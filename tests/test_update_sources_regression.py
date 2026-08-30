import importlib.util
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


if __name__ == "__main__":
    unittest.main()
