"""Command-line entry points for console memory-card deployment.

Three subcommands over one engine:

    psp-diff    preview changes without touching the card
    psp-apply   reconcile the card, verifying every write
    psp-size    report capacity, headroom, and size by logical owner
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

if __package__ in (None, ""):  # executed as a script by flake apps
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    from console import deploy  # type: ignore[no-redef]
else:
    from . import deploy

SYMBOLS = {
    "add": "+",
    "update": "~",
    "delete": "-",
    "modified": "!",
    "unchanged": " ",
}


def _load_context(args: argparse.Namespace) -> tuple[Path, dict, dict, list]:
    dest = Path(args.dest).resolve()
    if not dest.is_dir():
        raise deploy.ConsoleError(f"{dest} is not a directory (is the card mounted?)")
    # A card with no generation is fine. Refuse only when the control directory
    # exists but is unusable, which would make the card's managed state unknowable.
    control = dest / deploy.CONTROL_DIR
    if control.exists() and not control.is_dir():
        raise deploy.ConsoleError(f"{control} exists but is not a directory")

    desired = deploy.read_manifest(Path(args.manifest))
    previous = deploy.load_previous(dest)
    for entry in desired.values():
        deploy.validate_relative(entry.path)
    changes = deploy.plan(dest, desired, previous)
    return dest, desired, previous, changes


def cmd_diff(args: argparse.Namespace) -> int:
    dest, desired, _previous, changes = _load_context(args)
    counts = {action: 0 for action in SYMBOLS}
    for change in changes:
        counts[change.action] = counts.get(change.action, 0) + 1

    report = deploy.account_space(dest, desired, changes)

    print(f"card:       {dest}")
    print(
        f"generation: {deploy.read_generation(dest)} -> {deploy.read_generation(dest) + 1}"
    )
    print(f"desired:    {len(desired)} file(s)")
    print(
        "changes:    "
        + ", ".join(
            f"{counts[a]} {a}"
            for a in ("add", "update", "delete", "modified", "unchanged")
        )
    )
    print()
    for change in changes:
        if change.action == "unchanged" and not args.verbose:
            continue
        marker = SYMBOLS[change.action]
        size = change.entry.size if change.entry else (change.current_size or 0)
        owner = change.entry.owner if change.entry else ""
        detail = f" ({change.current_hash[:12]})" if change.action == "modified" else ""
        print(
            f"  {marker} {change.action:<9} {deploy.human(size):>10}  {change.path}{detail}"
        )
        if owner:
            print(f"      {'':<9} {'':<10}  owner: {owner}")

    print()
    print(f"  free space:     {deploy.human(report.filesystem_free)}")
    print(f"  net additional: {deploy.human(report.net_additional)}")
    print(f"  staging needed: {deploy.human(report.staging_required)}")
    print(f"  headroom after: {deploy.human(report.projected_headroom)}")
    if not report.sufficient:
        print("\n  INSUFFICIENT SPACE: refusing to apply.")
        return 1
    if counts["modified"]:
        print(
            f"\n  {counts['modified']} managed file(s) changed on the card. "
            "Apply needs --force to replace them."
        )
    if any(c.is_write or c.is_freed for c in changes):
        print("\n  Run 'psp-apply' to make these changes.")
    else:
        print("\n  Already up to date.")
    return 0


def cmd_apply(args: argparse.Namespace) -> int:
    dest, desired, _previous, changes = _load_context(args)

    if not args.yes:
        cmd_diff(argparse.Namespace(**{**vars(args), "verbose": False}))
        print()
        answer = input("Apply these changes? [y/N] ").strip().lower()
        if answer not in ("y", "yes"):
            print("aborted; nothing was changed")
            return 1

    report = deploy.account_space(dest, desired, changes)
    if not report.sufficient:
        raise deploy.ConsoleError(
            f"insufficient space: {deploy.human(report.projected_headroom)} headroom "
            f"after writing {deploy.human(report.net_additional)} and staging "
            f"{deploy.human(report.staging_required)}"
        )

    result = deploy.apply(dest, Path(args.source), desired, changes, force=args.force)

    print()
    print(f"generation {result.generation} committed")
    print(f"  added:     {len(result.added)} ({deploy.human(result.bytes_added)})")
    print(f"  updated:   {len(result.updated)} ({deploy.human(result.bytes_updated)})")
    print(f"  deleted:   {len(result.deleted)} ({deploy.human(result.bytes_deleted)})")
    print(f"  unchanged: {result.unchanged}")
    return 0


def cmd_size(args: argparse.Namespace) -> int:
    dest, desired, _previous, changes = _load_context(args)
    report = deploy.account_space(dest, desired, changes)

    print(f"card:              {dest}")
    print(f"filesystem total:  {deploy.human(report.filesystem_capacity)} (exact)")
    print(f"filesystem free:   {deploy.human(report.filesystem_free)} (exact)")
    print(f"managed now:       {deploy.human(report.current_managed)} (exact)")
    print(f"managed desired:   {deploy.human(report.desired_logical)} (exact, logical)")
    print(f"  added:           {deploy.human(report.bytes_added)}")
    print(f"  updated:         {deploy.human(report.bytes_updated)}")
    print(f"  deleted:         {deploy.human(report.bytes_deleted)}")
    print(f"  net additional:  {deploy.human(report.net_additional)}")
    print(
        f"staging needed:    {deploy.human(report.staging_required)} (exact, updates)"
    )
    print(f"headroom after:    {deploy.human(report.projected_headroom)}")
    print()
    print("note: physical FAT allocation exceeds logical size by cluster rounding;")
    print("      figures above are logical unless marked exact.")

    if args.by_module:
        print()
        print(f"{'owner':<32} {'files':>6} {'logical':>12}")
        for owner, count, size in deploy.by_owner(desired.values()):
            print(f"{owner:<32} {count:>6} {deploy.human(size):>12}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="psp", description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    def common(p: argparse.ArgumentParser) -> None:
        p.add_argument("dest", help="mounted card path")
        p.add_argument("--manifest", required=True, help="generated manifest (JSONL)")
        p.add_argument(
            "--first-run",
            action="store_true",
            help="allow a card with no previous generation",
        )

    diff = sub.add_parser("diff", help="preview changes")
    common(diff)
    diff.add_argument(
        "-v", "--verbose", action="store_true", help="include unchanged files"
    )
    diff.set_defaults(func=cmd_diff)

    apply_cmd = sub.add_parser("apply", help="reconcile the card")
    common(apply_cmd)
    apply_cmd.add_argument("--source", required=True, help="generated file tree")
    apply_cmd.add_argument(
        "--yes", action="store_true", help="skip the confirmation prompt"
    )
    apply_cmd.add_argument(
        "--force",
        action="store_true",
        help="replace managed files that were changed on the card",
    )
    apply_cmd.add_argument("-v", "--verbose", action="store_true")
    apply_cmd.set_defaults(func=cmd_apply)

    size = sub.add_parser("size", help="capacity and size report")
    common(size)
    size.add_argument(
        "--by-module", action="store_true", help="break size down by logical owner"
    )
    size.set_defaults(func=cmd_size)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except deploy.ConsoleError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("interrupted", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
