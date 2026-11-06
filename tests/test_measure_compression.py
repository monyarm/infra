import importlib.util
import pathlib
import subprocess
import unittest
from unittest import mock

SPEC = importlib.util.spec_from_file_location(
    "measure_compression",
    pathlib.Path(__file__).parents[1] / "measure-compression.py",
)
assert SPEC is not None and SPEC.loader is not None
measure_compression = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(measure_compression)


class BuildRetryTests(unittest.TestCase):
    def test_build_retries_after_a_failed_attempt(self):
        failed = subprocess.CompletedProcess([], 1, stdout="")
        succeeded = subprocess.CompletedProcess([], 0, stdout="/nix/store/result\n")

        with mock.patch.object(
            measure_compression.subprocess,
            "run",
            side_effect=[failed, failed, succeeded],
        ) as run:
            result = measure_compression.build_one(
                "doom", "brightmaps", "real", "/nix/store/test.drv", 1, 1
            )

        self.assertEqual(result, ("doom", "brightmaps", "real", "/nix/store/result"))
        self.assertEqual(run.call_count, 3)
        self.assertIn("--option builders ''", run.call_args_list[2].args[0])


if __name__ == "__main__":
    unittest.main()
