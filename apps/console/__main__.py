"""Single entry point for the console CLIs.

The subcommand is derived from the invoked program's name, so `psp-diff`,
`psp-apply`, and `psp-size` are symlinks to this one module. That keeps the
three tools byte-identical apart from argv[0], and keeps store paths out of the
generated files.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

SUBCOMMANDS = ("diff", "apply", "size")


def subcommand_for(program: str) -> str:
    name = Path(program).name
    stem = name.removeprefix("psp-")
    if stem not in SUBCOMMANDS:
        raise SystemExit(f"unknown console tool: {name}")
    return stem


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    try:
        from console.cli import main as cli_main
    except ModuleNotFoundError:
        # Running straight from a source checkout.
        sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
        from console.cli import main as cli_main

    return cli_main([subcommand_for(os.path.basename(sys.argv[0])), *argv])


if __name__ == "__main__":
    raise SystemExit(main())
