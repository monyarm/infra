"""Deployment engine tests.

Every test runs against a temporary directory that stands in for a mounted
card, so no PSP hardware is involved. The invariants under test are the ones
the whole design exists to protect: unmanaged data survives, only previously
managed files are ever deleted, and external edits are never silently lost.

Run directly:  python3 apps/console/test_deploy.py
"""

from __future__ import annotations

import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from console import deploy


def entry_for(text: str, owner: str = "") -> deploy.Entry:
    raw = text.encode("utf-8")
    return deploy.Entry(
        path="",
        hash=deploy.hashlib.sha256(raw).hexdigest(),
        size=len(raw),
        owner=owner,
    )


class CardTest(unittest.TestCase):
    """Base fixture providing a fake card and a fake generated tree."""

    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="psp-test-"))
        self.card = self.tmp / "card"
        self.gen = self.tmp / "gen"
        self.card.mkdir()
        self.gen.mkdir()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)

    # -- helpers ---------------------------------------------------------

    def entry(self, rel: str, text: str, owner: str = "") -> deploy.Entry:
        raw = text.encode("utf-8")
        source = self.gen / rel
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_text(text, encoding="utf-8")
        return deploy.Entry(
            path=rel,
            hash=deploy.hashlib.sha256(raw).hexdigest(),
            size=len(raw),
            owner=owner,
        )

    def manifest(self, entries: list[deploy.Entry], name: str = "manifest") -> Path:
        path = self.tmp / name
        deploy.write_manifest(path, entries)
        return path

    def desired(self, entries: list[deploy.Entry]) -> dict[str, deploy.Entry]:
        return {e.path: e for e in entries}

    def apply(
        self, entries: list[deploy.Entry], *, force: bool = False
    ) -> deploy.ApplyResult:
        desired = self.desired(entries)
        previous = deploy.load_previous(self.card)
        changes = deploy.plan(self.card, desired, previous)
        return deploy.apply(self.card, self.gen, desired, changes, force=force)

    def read(self, rel: str) -> str:
        return (self.card / rel).read_text(encoding="utf-8")

    # -- manifest --------------------------------------------------------

    def test_manifest_roundtrip_and_sorted(self) -> None:
        entries = [self.entry("z.txt", "z"), self.entry("a.txt", "a")]
        path = self.manifest(entries)
        text = path.read_text(encoding="utf-8")
        self.assertLess(text.index('"a.txt"'), text.index('"z.txt"'))
        reloaded = deploy.read_manifest(path)
        self.assertEqual(set(reloaded), {"a.txt", "z.txt"})
        self.assertEqual(reloaded["a.txt"].size, 1)

    def test_manifest_rejects_duplicate_paths(self) -> None:
        e = self.entry("dup.txt", "x")
        path = self.tmp / "bad-manifest"
        path.write_text(e.to_json() + "\n" + e.to_json() + "\n", encoding="utf-8")
        with self.assertRaises(deploy.ConsoleError):
            deploy.read_manifest(path)

    def test_manifest_rejects_malformed_record(self) -> None:
        path = self.tmp / "broken"
        path.write_text('{"path":"a.txt"}\n', encoding="utf-8")
        with self.assertRaises(deploy.ConsoleError):
            deploy.read_manifest(path)

    def test_key_order_is_fixed(self) -> None:
        e = self.entry("k.txt", "v")
        parsed = json.loads(e.to_json())
        self.assertEqual(list(parsed), ["path", "hash", "size", "owner"])

    # -- path safety -----------------------------------------------------

    def test_rejects_traversal(self) -> None:
        with self.assertRaises(deploy.ConsoleError):
            deploy.validate_relative("../escape")

    def test_rejects_absolute(self) -> None:
        with self.assertRaises(deploy.ConsoleError):
            deploy.validate_relative("/etc/passwd")

    def test_rejects_reserved_control_dir(self) -> None:
        for bad in (".psp-nix/manifest", ".psp-nix"):
            with self.assertRaises(deploy.ConsoleError):
                deploy.validate_relative(bad)

    def test_rejects_empty_component(self) -> None:
        with self.assertRaises(deploy.ConsoleError):
            deploy.validate_relative("a//b")

    def test_allows_ordinary_psp_paths(self) -> None:
        for good in (
            "PSP/GAME/Lumines/EBOOT.PBP",
            "SEPLUGINS/PLUGINS.TXT",
            "ICON0.PNG",
            "PSP/SAVEDATA/SLUS00001/DATA.BIN",
        ):
            deploy.validate_relative(good)

    def test_resolve_within_refuses_escape(self) -> None:
        link_parent = self.card / "evil"
        link_parent.mkdir()
        outside = self.tmp / "outside"
        outside.mkdir()
        (outside / "target.txt").write_text("data", encoding="utf-8")
        os.symlink(outside, link_parent / "link")
        with self.assertRaises(deploy.ConsoleError):
            deploy.resolve_within(self.card, "evil/link/target.txt")

    # -- planning --------------------------------------------------------

    def test_add_detected_when_missing(self) -> None:
        e = self.entry("new.txt", "hello")
        changes = deploy.plan(self.card, {"new.txt": e}, {})
        self.assertEqual([c.action for c in changes], ["add"])

    def test_unchanged_detected(self) -> None:
        e = self.entry("same.txt", "hello")
        self.apply([e])
        changes = deploy.plan(self.card, {"same.txt": e}, {"same.txt": e})
        self.assertEqual([c.action for c in changes], ["unchanged"])

    def test_update_detected_on_content_change(self) -> None:
        first = self.entry("f.txt", "one")
        self.apply([first])
        second = self.entry("f.txt", "two")
        changes = deploy.plan(self.card, {"f.txt": second}, {"f.txt": first})
        self.assertEqual([c.action for c in changes], ["update"])

    def test_modified_detected_on_external_edit(self) -> None:
        e = self.entry("f.txt", "one")
        self.apply([e])
        (self.card / "f.txt").write_text("tampered", encoding="utf-8")
        changes = deploy.plan(self.card, {"f.txt": e}, {"f.txt": e})
        self.assertEqual([c.action for c in changes], ["modified"])

    def test_delete_only_for_previous_managed_paths(self) -> None:
        old = self.entry("gone.txt", "bye")
        self.apply([old])
        changes = deploy.plan(self.card, {}, {"gone.txt": old})
        self.assertEqual([c.action for c in changes], ["delete"])

    def test_unmanaged_file_is_never_a_delete_candidate(self) -> None:
        (self.card / "SAVE.BIN").write_text("user data", encoding="utf-8")
        changes = deploy.plan(self.card, {}, {})
        self.assertEqual(changes, [])

    # -- apply: core invariants ------------------------------------------

    def test_apply_creates_files(self) -> None:
        self.apply([self.entry("a/b.txt", "content", owner="games.x")])
        self.assertEqual(self.read("a/b.txt"), "content")
        self.assertEqual(deploy.read_generation(self.card), 1)

    def test_apply_updates_changed_content(self) -> None:
        self.apply([self.entry("f.txt", "one")])
        self.apply([self.entry("f.txt", "two")])
        self.assertEqual(self.read("f.txt"), "two")
        self.assertEqual(deploy.read_generation(self.card), 2)

    def test_apply_deletes_undeclared_managed_file(self) -> None:
        keep = self.entry("keep.txt", "k")
        drop = self.entry("drop.txt", "d")
        self.apply([keep, drop])
        self.apply([keep])
        self.assertFalse((self.card / "drop.txt").exists())
        self.assertTrue((self.card / "keep.txt").exists())

    def test_unmanaged_file_survives_apply(self) -> None:
        (self.card / "USER.SAV").write_text("precious", encoding="utf-8")
        self.apply([self.entry("a.txt", "a")])
        self.apply([self.entry("b.txt", "b")])
        self.assertEqual(
            (self.card / "USER.SAV").read_text(encoding="utf-8"), "precious"
        )

    def test_unmanaged_file_in_managed_dir_survives_deletion(self) -> None:
        managed = self.entry("GAME/EBOOT.PBP", "pbp")
        self.apply([managed])
        (self.card / "GAME" / "SAVE.BIN").write_text("saves", encoding="utf-8")
        self.apply([])
        self.assertFalse((self.card / "GAME" / "EBOOT.PBP").exists())
        self.assertTrue((self.card / "GAME" / "SAVE.BIN").exists())
        self.assertTrue(
            (self.card / "GAME").is_dir(), "dir must survive: still holds user data"
        )

    def test_empty_dir_is_pruned(self) -> None:
        deep = self.entry("A/B/C.txt", "x")
        self.apply([deep])
        self.apply([])
        self.assertFalse((self.card / "A").exists())

    def test_dir_with_unmanaged_file_is_not_pruned(self) -> None:
        deep = self.entry("A/B/C.txt", "x")
        self.apply([deep])
        (self.card / "A" / "keepme").write_text("u", encoding="utf-8")
        self.apply([])
        self.assertTrue((self.card / "A").is_dir())
        self.assertTrue((self.card / "A" / "keepme").exists())

    def test_modified_file_blocks_apply_without_force(self) -> None:
        e = self.entry("f.txt", "one")
        self.apply([e])
        (self.card / "f.txt").write_text("user edit", encoding="utf-8")
        with self.assertRaises(deploy.ConsoleError) as ctx:
            self.apply([e])
        self.assertIn("--force", str(ctx.exception))
        self.assertEqual((self.card / "f.txt").read_text(encoding="utf-8"), "user edit")

    def test_force_replaces_modified_file(self) -> None:
        e = self.entry("f.txt", "one")
        self.apply([e])
        (self.card / "f.txt").write_text("user edit", encoding="utf-8")
        self.apply([e], force=True)
        self.assertEqual(self.read("f.txt"), "one")

    def test_failed_apply_leaves_generation_uncommitted(self) -> None:
        e = self.entry("f.txt", "one")
        self.apply([e])
        before = deploy.read_generation(self.card)
        (self.card / "f.txt").write_text("tampered", encoding="utf-8")
        with self.assertRaises(deploy.ConsoleError):
            self.apply([e])
        self.assertEqual(deploy.read_generation(self.card), before)

    def test_symlink_at_managed_path_is_not_replaced(self) -> None:
        e = self.entry("f.txt", "one")
        self.apply([e])
        outside = self.tmp / "outside.txt"
        outside.write_text("external", encoding="utf-8")
        (self.card / "f.txt").unlink()
        os.symlink(outside, self.card / "f.txt")
        desired = self.desired([e])
        previous = deploy.load_previous(self.card)
        changes = deploy.plan(self.card, desired, previous)
        self.assertEqual([c.action for c in changes], ["modified"])
        with self.assertRaises(deploy.ConsoleError):
            deploy.apply(self.card, self.gen, desired, changes, force=True)
        self.assertEqual(outside.read_text(encoding="utf-8"), "external")

    def test_symlinked_managed_path_detected_as_modified(self) -> None:
        e = self.entry("f.txt", "one")
        self.apply([e])
        outside = self.tmp / "outside.txt"
        outside.write_text("external", encoding="utf-8")
        (self.card / "f.txt").unlink()
        os.symlink(outside, self.card / "f.txt")
        changes = deploy.plan(self.card, self.desired([e]), {"f.txt": e})
        self.assertEqual([c.action for c in changes], ["modified"])

    # -- generations -----------------------------------------------------

    def test_generation_pointer_advances(self) -> None:
        self.apply([self.entry("a.txt", "1")])
        self.assertEqual(deploy.read_generation(self.card), 1)
        self.apply([self.entry("a.txt", "2")])
        self.assertEqual(deploy.read_generation(self.card), 2)

    def test_generation_manifest_is_readable(self) -> None:
        e = self.entry("a.txt", "1")
        self.apply([e])
        gen = deploy.read_generation(self.card)
        stored = deploy.read_manifest(deploy.previous_manifest_path(self.card, gen))
        self.assertEqual(set(stored), {"a.txt"})

    def test_missing_generation_manifest_refuses(self) -> None:
        self.apply([self.entry("a.txt", "1")])
        shutil.rmtree(self.card / deploy.CONTROL_DIR / "generations")
        with self.assertRaises(deploy.ConsoleError):
            deploy.load_previous(self.card)

    def test_corrupt_generation_pointer_refuses(self) -> None:
        self.apply([self.entry("a.txt", "1")])
        (self.card / deploy.CONTROL_DIR / deploy.GENERATION_FILE).write_text(
            "not-a-number", encoding="utf-8"
        )
        with self.assertRaises(deploy.ConsoleError):
            deploy.read_generation(self.card)

    def test_control_dir_conflict_is_reported(self) -> None:
        e = self.entry("a.txt", "1")
        self.apply([e])
        shutil.rmtree(self.card / deploy.CONTROL_DIR)
        (self.card / deploy.CONTROL_DIR).write_text("i am a file", encoding="utf-8")
        desired = self.desired([e])
        with self.assertRaises(deploy.ConsoleError):
            deploy.apply(self.card, self.gen, desired, [], force=True)

    # -- space accounting ------------------------------------------------

    def test_space_accounting_arithmetic(self) -> None:
        old = self.entry("old.txt", "x" * 100)
        self.apply([old])
        new = self.entry("new.txt", "y" * 300)
        desired = self.desired([new])
        changes = deploy.plan(self.card, desired, {"old.txt": old})
        report = deploy.account_space(self.card, desired, changes)
        self.assertEqual(report.bytes_added, 300)
        self.assertEqual(report.bytes_deleted, 100)
        self.assertEqual(report.net_additional, 200)
        self.assertEqual(report.desired_logical, 300)

    def test_update_requires_staging_space(self) -> None:
        first = self.entry("f.txt", "a" * 50)
        self.apply([first])
        second = self.entry("f.txt", "b" * 80)
        desired = self.desired([second])
        changes = deploy.plan(self.card, desired, {"f.txt": first})
        report = deploy.account_space(self.card, desired, changes)
        self.assertEqual(report.bytes_updated, 80, "new size of the updated file")
        self.assertEqual(report.net_additional, 30, "80 new - 50 freed")
        self.assertEqual(
            report.staging_required,
            80,
            "the staged copy exists beside the old one until the rename lands, "
            "so the transient need is the whole new file",
        )

    def test_by_owner_aggregation(self) -> None:
        rows = deploy.by_owner(
            [
                deploy.Entry("a", "h", 10, "games.x"),
                deploy.Entry("b", "h", 5, "games.x"),
                deploy.Entry("c", "h", 100, "homebrew.y"),
            ]
        )
        self.assertEqual(rows[0], ("homebrew.y", 1, 100))
        self.assertEqual(rows[1], ("games.x", 2, 15))

    def test_unattributed_bucket_exists(self) -> None:
        rows = deploy.by_owner([deploy.Entry("a", "h", 1, "")])
        self.assertEqual(rows[0][0], "<unattributed>")

    def test_headroom_flag_is_accurate(self) -> None:
        report = deploy.SpaceReport(
            filesystem_capacity=100,
            filesystem_free=1000,
            desired_logical=0,
            current_managed=0,
            bytes_added=10,
            bytes_updated=0,
            bytes_deleted=0,
            net_additional=10,
            staging_required=0,
            projected_headroom=990,
        )
        self.assertTrue(report.sufficient)

    # -- incomplete generation -------------------------------------------

    def test_missing_source_file_aborts(self) -> None:
        e = deploy.Entry(path="gone.txt", hash="0" * 64, size=1, owner="")
        desired = {"gone.txt": e}
        changes = deploy.plan(self.card, desired, {})
        with self.assertRaises(deploy.ConsoleError) as ctx:
            deploy.apply(self.card, self.gen, desired, changes, force=True)
        self.assertIn("incomplete generation", str(ctx.exception))

    # -- retry semantics -------------------------------------------------

    def test_second_apply_repairs_partial_first_apply(self) -> None:
        a = self.entry("a.txt", "a")
        b = self.entry("b.txt", "b")
        self.apply([a])
        # Simulate an interrupted apply: a landed, b never did.
        self.apply([a, b])
        self.assertEqual(deploy.read_generation(self.card), 2)
        self.assertEqual(self.read("b.txt"), "b")

    def test_repeated_apply_is_idempotent(self) -> None:
        entries = [self.entry("a.txt", "a"), self.entry("d/b.txt", "b")]
        self.apply(entries)
        result = self.apply(entries)
        self.assertEqual(result.added, [])
        self.assertEqual(result.updated, [])
        self.assertEqual(result.deleted, [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
