"""Declarative memory-card deployment for the console flake subsystem.

Consumes a Nix-built generation (a file tree plus an ownership manifest) and
reconciles a mounted card with it. The engine is deliberately generic: it knows
about paths, hashes, sizes, and owners, and nothing about PSP specifics.

Safety model
------------
* Only paths present in the *previous* manifest are ever deleted.
* Unmanaged files are never read, written, moved, or removed.
* Directories are removed only when provably empty.
* Symlinks are never followed out of the destination, and never replaced.
* A managed file changed outside this tool is never silently overwritten; the
  apply refuses unless explicitly forced.
* Free space is checked before any destructive write.
* The generation pointer is committed only after every write verifies.

Deliberately absent: backups, rollback, and a write-ahead journal. An
interrupted apply is repaired by running apply again.
"""

from __future__ import annotations

import dataclasses
import hashlib
import json
import os
import shutil
from collections.abc import Iterable, Sequence
from pathlib import Path

CONTROL_DIR = ".psp-nix"
GENERATION_FILE = "generation"
MANIFEST_FILE = "manifest"
STAGE_DIR = ".psp-nix-stage"

CHUNK = 1024 * 1024


class ConsoleError(Exception):
    """Fatal, user-facing deployment error."""


# --------------------------------------------------------------------------
# Manifest
# --------------------------------------------------------------------------


@dataclasses.dataclass(frozen=True)
class Entry:
    path: str
    hash: str
    size: int
    owner: str

    def to_json(self) -> str:
        # Key order is fixed so manifests are byte-reproducible.
        return json.dumps(
            {
                "path": self.path,
                "hash": self.hash,
                "size": self.size,
                "owner": self.owner,
            },
            separators=(",", ":"),
            sort_keys=False,
        )


def read_manifest(path: Path) -> dict[str, Entry]:
    """Parse a manifest. Invalid content is an error, never a silent reset."""
    if not path.is_file():
        return {}
    entries: dict[str, Entry] = {}
    with path.open("r", encoding="utf-8") as handle:
        for lineno, line in enumerate(handle, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                raw = json.loads(line)
                entry = Entry(
                    path=str(raw["path"]),
                    hash=str(raw["hash"]),
                    size=int(raw["size"]),
                    owner=str(raw.get("owner", "")),
                )
            except (ValueError, KeyError, TypeError) as error:
                raise ConsoleError(
                    f"{path}:{lineno}: malformed manifest record: {error}"
                ) from error
            if entry.path in entries:
                raise ConsoleError(f"{path}:{lineno}: duplicate path {entry.path!r}")
            entries[entry.path] = entry
    return entries


def write_manifest(path: Path, entries: Iterable[Entry]) -> None:
    """Write sorted-by-path JSONL atomically."""
    ordered = sorted(entries, key=lambda e: e.path)
    temp = path.with_name(path.name + ".tmp")
    with temp.open("w", encoding="utf-8") as handle:
        for entry in ordered:
            handle.write(entry.to_json() + "\n")
    os.replace(temp, path)


def hash_file(path: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as handle:
        while chunk := handle.read(CHUNK):
            digest.update(chunk)
            size += len(chunk)
    return digest.hexdigest(), size


# --------------------------------------------------------------------------
# Path safety
# --------------------------------------------------------------------------


def is_reserved(path: str) -> bool:
    return path == CONTROL_DIR or path.startswith(CONTROL_DIR + "/")


def validate_relative(path: str) -> None:
    """Reject anything that could escape the destination or corrupt FAT32."""
    if not path:
        raise ConsoleError("empty destination path")
    if path.startswith("/"):
        raise ConsoleError(f"absolute destination path: {path!r}")
    if "\\" in path:
        raise ConsoleError(f"backslash in destination path: {path!r}")
    parts = path.split("/")
    for part in parts:
        if part == "":
            raise ConsoleError(f"empty path component in {path!r}")
        if part in (".", ".."):
            raise ConsoleError(f"unsafe path component in {path!r}")
    if is_reserved(path):
        raise ConsoleError(f"destination inside reserved {CONTROL_DIR}/: {path!r}")
    if path == STAGE_DIR or path.startswith(STAGE_DIR + "/"):
        raise ConsoleError(f"destination inside reserved staging area: {path!r}")


def resolve_within(root: Path, relative: str) -> Path:
    """Resolve relative under root, refusing anything that escapes it.

    Uses realpath so a symlink planted inside the destination cannot redirect a
    write outside the card.
    """
    validate_relative(relative)
    candidate = root / relative
    root_real = root.resolve()
    # Strict=False: the leaf may legitimately not exist yet.
    resolved = candidate.resolve(strict=False)
    if resolved != root_real and root_real not in resolved.parents:
        raise ConsoleError(f"destination escapes the mounted card: {relative!r}")
    return candidate


# --------------------------------------------------------------------------
# Planning
# --------------------------------------------------------------------------


@dataclasses.dataclass
class Change:
    action: str  # add | update | delete | unchanged | modified
    path: str
    entry: Entry | None = None
    current_hash: str | None = None
    current_size: int | None = None

    @property
    def is_write(self) -> bool:
        return self.action in ("add", "update")

    @property
    def is_freed(self) -> bool:
        return self.action == "delete"


def classify_existing(
    dest: Path, relative: str, desired: Entry, baseline: Entry | None
) -> tuple[str, str | None, int | None]:
    """Return (state, on-card hash, on-card size) for one managed file.

    A hash mismatch alone is ambiguous: it could mean the generation simply
    moved on, or that somebody edited the file on the card. The previously
    recorded hash disambiguates it:

      not on the card                -> add
      on-card == desired             -> unchanged
      on-card == previous baseline   -> update (our own new generation)
      on-card != previous baseline   -> modified (an external edit)

    Anything the baseline cannot vouch for is treated as `modified`, i.e. we
    refuse rather than guess.
    """
    target = dest / relative
    if target.is_symlink():
        # A managed path replaced by a symlink is never silently clobbered.
        return "modified", None, None
    if not target.exists():
        return "add", None, None
    if not target.is_file():
        return "modified", None, None

    actual, size = hash_file(target)
    if actual == desired.hash:
        return "unchanged", actual, size
    if baseline is not None and baseline.hash == actual:
        return "update", actual, size
    return "modified", actual, size


def plan(
    dest: Path, desired: dict[str, Entry], previous: dict[str, Entry]
) -> list[Change]:
    """Compare desired vs previously-managed vs on-card state.

    Deletion candidates come only from `previous`, so a file this tool never
    managed can never be scheduled for removal.
    """
    changes: list[Change] = []
    for path in sorted(desired):
        entry = desired[path]
        state, actual, size = classify_existing(dest, path, entry, previous.get(path))
        changes.append(Change(state, path, entry, actual, size))

    for path in sorted(previous):
        if path in desired:
            continue
        target = dest / path
        if target.is_symlink() or not target.exists():
            # Already gone; nothing to free and nothing to delete.
            continue
        actual, size = (None, None)
        if target.is_file():
            actual, size = hash_file(target)
        changes.append(Change("delete", path, None, actual, size))

    return changes


# --------------------------------------------------------------------------
# Space accounting
# --------------------------------------------------------------------------


@dataclasses.dataclass
class SpaceReport:
    filesystem_capacity: int
    filesystem_free: int
    desired_logical: int
    current_managed: int
    bytes_added: int
    bytes_updated: int
    bytes_deleted: int
    net_additional: int
    staging_required: int
    projected_headroom: int

    @property
    def sufficient(self) -> bool:
        return self.projected_headroom >= 0


def account_space(
    dest: Path, desired: dict[str, Entry], changes: Sequence[Change]
) -> SpaceReport:
    """Exact where possible, conservative otherwise.

    Logical sizes are exact (they come from the manifest). Physical allocation
    on FAT is cluster-dependent and is deliberately *not* claimed here; only
    free-space headroom is checked, and with a one-file staging buffer so an
    update never needs both copies on disk longer than necessary.
    """
    usage = shutil.disk_usage(dest)
    desired_logical = sum(e.size for e in desired.values())

    added = sum(c.entry.size for c in changes if c.action == "add" and c.entry)
    updated = sum(c.entry.size for c in changes if c.action == "update" and c.entry)
    deleted = sum(c.current_size or 0 for c in changes if c.action == "delete")

    # Everything this tool currently owns on the card, regardless of action.
    current_managed = sum(
        c.current_size or 0
        for c in changes
        if c.action in ("unchanged", "update", "modified", "delete")
    )

    # An update frees its old content, so only the growth counts as new usage.
    updated_freed = sum((c.current_size or 0) for c in changes if c.action == "update")
    net = added + updated - updated_freed - deleted
    # Peak extra space while writing: for each replaced file, the staged copy
    # exists alongside the old one until the rename, so the transient need is
    # the whole new file, not just the growth. Summed per file because
    # replacements happen one at a time.
    staging = sum(
        (c.entry.size if c.entry else 0)
        for c in changes
        if c.action in ("update", "modified")
    )
    headroom = usage.free - net - staging

    return SpaceReport(
        filesystem_capacity=usage.total,
        filesystem_free=usage.free,
        desired_logical=desired_logical,
        current_managed=current_managed,
        bytes_added=added,
        bytes_updated=updated,
        bytes_deleted=deleted,
        net_additional=net,
        staging_required=staging,
        projected_headroom=headroom,
    )


def by_owner(entries: Iterable[Entry]) -> list[tuple[str, int, int]]:
    """Aggregate size by logical owner, largest first."""
    totals: dict[str, list[int]] = {}
    for entry in entries:
        bucket = totals.setdefault(entry.owner or "<unattributed>", [0, 0])
        bucket[0] += 1
        bucket[1] += entry.size
    return sorted(
        ((owner, count, size) for owner, (count, size) in totals.items()),
        key=lambda row: (-row[2], row[0]),
    )


def human(size: int) -> str:
    value = float(size)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if abs(value) < 1024.0 or unit == "TiB":
            return f"{value:.1f} {unit}" if unit != "B" else f"{int(value)} B"
        value /= 1024.0
    return f"{value:.1f} TiB"


# --------------------------------------------------------------------------
# Generation bookkeeping
# --------------------------------------------------------------------------


def read_generation(dest: Path) -> int:
    pointer = dest / CONTROL_DIR / GENERATION_FILE
    if not pointer.is_file():
        return 0
    text = pointer.read_text(encoding="utf-8").strip()
    if not text.isdigit():
        raise ConsoleError(f"corrupt generation pointer at {pointer}")
    return int(text)


def previous_manifest_path(dest: Path, generation: int) -> Path:
    return dest / CONTROL_DIR / "generations" / str(generation) / MANIFEST_FILE


def load_previous(dest: Path) -> dict[str, Entry]:
    generation = read_generation(dest)
    if generation == 0:
        return {}
    path = previous_manifest_path(dest, generation)
    if not path.is_file():
        # A missing history entry means we cannot know what we own. Refusing is
        # the only safe response; assuming "nothing" would risk deleting data.
        raise ConsoleError(
            f"generation {generation} manifest is missing at {path}; "
            "refusing to act without knowing which files are managed"
        )
    return read_manifest(path)


def commit_generation(dest: Path, entries: Sequence[Entry]) -> int:
    """Record the new manifest, then advance the pointer. Pointer last."""
    generation = read_generation(dest) + 1
    target = previous_manifest_path(dest, generation)
    target.parent.mkdir(parents=True, exist_ok=True)
    write_manifest(target, entries)
    pointer = dest / CONTROL_DIR / GENERATION_FILE
    temp = pointer.with_name(pointer.name + ".tmp")
    temp.write_text(f"{generation}\n", encoding="utf-8")
    os.replace(temp, pointer)
    return generation


# --------------------------------------------------------------------------
# Empty-directory cleanup
# --------------------------------------------------------------------------


def prune_empty_dirs(dest: Path, relative: str) -> None:
    """Remove now-empty parents of `relative`, deepest first, stopping at root.

    rmdir only ever succeeds on an empty directory, so a user's file sitting
    inside a managed one keeps that directory alive. Nothing is ever removed
    recursively.
    """
    parts = relative.split("/")[:-1]
    for depth in range(len(parts), 0, -1):
        candidate = dest / "/".join(parts[:depth])
        if is_reserved("/".join(parts[:depth])):
            return
        try:
            candidate.rmdir()
        except (OSError, FileNotFoundError):
            # Non-empty or already gone: leave it, and everything above it.
            return


# --------------------------------------------------------------------------
# Apply
# --------------------------------------------------------------------------


@dataclasses.dataclass
class ApplyResult:
    added: list[str]
    updated: list[str]
    deleted: list[str]
    unchanged: int
    generation: int
    bytes_added: int
    bytes_updated: int
    bytes_deleted: int


def apply(
    dest: Path,
    source: Path,
    desired: dict[str, Entry],
    changes: Sequence[Change],
    *,
    force: bool,
) -> ApplyResult:
    """Reconcile the card. Raises before mutating on any unsafe condition."""
    control = dest / CONTROL_DIR
    if control.exists() and not control.is_dir():
        raise ConsoleError(f"{control} exists but is not a directory")

    modified = [c for c in changes if c.action == "modified"]
    if modified and not force:
        listing = "\n".join(f"    {c.path}" for c in modified[:20])
        more = "" if len(modified) <= 20 else f"\n  ... and {len(modified) - 20} more"
        raise ConsoleError(
            f"{len(modified)} managed file(s) changed on the card and would be "
            f"overwritten:\n  {listing}{more}\n"
            "Re-run with --force to replace them."
        )

    # Deletes run after writes so a failed write never loses old content.
    result = ApplyResult([], [], [], 0, 0, 0, 0, 0)
    for change in changes:
        if change.action in ("add", "update", "modified"):
            assert change.entry is not None  # set by plan() for every write
            target = resolve_within(dest, change.path)
            if target.is_symlink():
                raise ConsoleError(f"refusing to replace symlink at {change.path}")
            source_file = resolve_within(source, change.path)
            if not source_file.is_file():
                raise ConsoleError(
                    f"generated tree is missing {change.path}; refusing to apply an "
                    "incomplete generation"
                )
            target.parent.mkdir(parents=True, exist_ok=True)
            # Stage then rename: a crash mid-copy cannot leave a half-written
            # file where the managed path claims to be complete.
            staging = target.with_name(target.name + ".psp-new")
            shutil.copyfile(source_file, staging)
            if hash_file(staging)[0] != change.entry.hash:
                staging.unlink(missing_ok=True)
                raise ConsoleError(f"staged copy of {change.path} failed verification")
            os.replace(staging, target)
            if change.action == "add":
                result.added.append(change.path)
                result.bytes_added += change.entry.size
            else:
                result.updated.append(change.path)
                result.bytes_updated += change.entry.size

        elif change.action == "delete":
            target = dest / change.path
            if target.is_symlink() or target.is_file():
                target.unlink()
                result.deleted.append(change.path)
                result.bytes_deleted += change.current_size or 0
            prune_empty_dirs(dest, change.path)

        elif change.action == "unchanged":
            result.unchanged += 1

    # Verify every managed file before committing the generation.
    for path, entry in sorted(desired.items()):
        target = dest / path
        if not target.is_file():
            raise ConsoleError(f"verification failed: {path} is missing after apply")
        actual, size = hash_file(target)
        if actual != entry.hash or size != entry.size:
            raise ConsoleError(
                f"verification failed: {path} does not match the manifest"
            )

    result.generation = commit_generation(dest, list(desired.values()))
    return result
