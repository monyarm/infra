import contextlib
import importlib.util
import io
import os
import pathlib
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    "update_sources",
    os.environ.get(
        "UPDATE_SOURCES_PATH",
        pathlib.Path(__file__).parents[1] / "update-sources.py",
    ),
)
assert SPEC is not None and SPEC.loader is not None
update_sources = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(update_sources)


class CargoLockTests(unittest.TestCase):
    def test_existing_lockfile_is_used_without_regeneration(self):
        lock_text = "version = 4\n"
        with tempfile.TemporaryDirectory() as temp_dir:
            pathlib.Path(temp_dir, "Cargo.lock").write_text(lock_text)

            self.assertEqual(update_sources.load_cargo_lock(temp_dir), lock_text)

    def test_missing_lockfile_is_not_treated_as_generated(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            self.assertIsNone(update_sources.load_cargo_lock(temp_dir))


class NpmNormalizationTests(unittest.TestCase):
    def test_platform_filter_selects_host_libc_variant(self):
        bindings, _ = update_sources.npm_normalization_hook("platform-optional:rollup")

        self.assertIn("npmLibc = if pkgs.stdenv.hostPlatform.isMusl", bindings)
        self.assertIn("@rollup/rollup-${npmOs}-${npmArch}", bindings)


class SelectorTests(unittest.TestCase):
    def test_namespace_selector_matches_every_child(self):
        self.assertTrue(update_sources.key_matches("redump.psp", ["redump"]))
        self.assertTrue(update_sources.key_matches("redump", ["redump"]))

    def test_deep_path_selector_matches_exactly_one_entry(self):
        self.assertTrue(update_sources.key_matches("redump.psp", ["redump.psp"]))
        self.assertFalse(update_sources.key_matches("redump.ps1", ["redump.psp"]))

    def test_prefix_selector_does_not_match_sibling_namespace(self):
        # the point of matching on "." rather than str.startswith
        self.assertFalse(update_sources.key_matches("redump2.psp", ["redump"]))

    def test_any_selector_can_match(self):
        self.assertTrue(update_sources.key_matches("tools.wadptr", ["redump", "tools"]))
        self.assertFalse(update_sources.key_matches("fonts.x", ["redump", "tools"]))

    def test_no_selectors_matches_nothing(self):
        self.assertFalse(update_sources.key_matches("tools.wadptr", []))


class ParseArgsTests(unittest.TestCase):
    def test_no_args_means_unscoped_full_run(self):
        args = update_sources.parse_args([])

        self.assertFalse(args.append)
        self.assertEqual(args.selectors, [])
        self.assertEqual(args.sections, [])

    def test_positional_selectors_and_sections(self):
        args = update_sources.parse_args(
            ["redump", "tools.wadptr", "--section", "romhacking", "-s", "zip"]
        )

        self.assertEqual(args.selectors, ["redump", "tools.wadptr"])
        self.assertEqual(args.sections, ["romhacking", "zip"])

    def test_append_flag(self):
        self.assertTrue(update_sources.parse_args(["--append"]).append)

    def test_unknown_flag_is_rejected(self):
        # regression: unknown args used to be ignored, silently degrading
        # into a full-repo refresh
        with (
            contextlib.redirect_stderr(io.StringIO()),
            self.assertRaises(SystemExit) as ctx,
        ):
            update_sources.parse_args(["--categorie", "redump"])

        self.assertEqual(ctx.exception.code, 2)

    def test_help_exits_zero(self):
        with (
            contextlib.redirect_stdout(io.StringIO()),
            self.assertRaises(SystemExit) as ctx,
        ):
            update_sources.parse_args(["--help"])

        self.assertEqual(ctx.exception.code, 0)


if __name__ == "__main__":
    unittest.main()
