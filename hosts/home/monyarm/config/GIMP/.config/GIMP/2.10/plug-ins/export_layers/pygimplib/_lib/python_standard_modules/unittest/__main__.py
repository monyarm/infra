"""Main entry point"""

import sys

if sys.argv[0].endswith("__main__.py"):
    sys.argv[0] = "python -m unittest"

__unittest = True

from .main import USAGE_AS_MAIN, TestProgram, main

TestProgram.USAGE = USAGE_AS_MAIN

main(module=None)
