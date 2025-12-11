#!/bin/bash
# Exit immediately on error, treat unset variables as an error, and handle pipeline failures.
set -euo pipefail

# --- This script compiles and runs a BASIC program using FreeBASIC. ---
# It automatically handles source files with or without a shebang.

# --- Configuration ---
# Set to a writable and executable directory if /tmp is not suitable.
TEMP_EXE_DIR=""
FBC="/usr/bin/fbc"
FBC_FLAGS="-forcelang qb"

# --- Functions ---
# Cleanup function to remove temporary files. This is called on script exit.
cleanup() {
  # The '''|| true''' prevents the trap from exiting with an error if the files don'''t exist.
  rm -f "$tempbas" "$tempexe" || true
}

# Function to display usage information if the script is called incorrectly.
usage() {
  echo "Usage: $0 <basic_source_file>"
  exit 1
}

# --- Main Script ---
# Ensure a file has been provided.
if [[ $# -eq 0 ]]; then
  usage
fi

# Set up temporary files for the compilation process.
# The '''trap''' command ensures the '''cleanup''' function is called when the script exits.
trap cleanup EXIT
tempbas=$(mktemp)
tempexe=$(mktemp ${TEMP_EXE_DIR:+-p "$TEMP_EXE_DIR"})

fullpath=$(readlink -f "$1")

# Compile the BASIC source, stripping the shebang if it exists.
if ! grep -q '''^#!''' "$fullpath"; then
  # No shebang found, compile directly.
  "$FBC" "$FBC_FLAGS" -x "$tempexe" "$fullpath"
else
  # Shebang found, strip it before compiling.
  grep -v '''^#!''' "$fullpath" >"$tempbas"
  "$FBC" "$FBC_FLAGS" -x "$tempexe" "$tempbas"
fi

# If the script is called as "fbrun", drop that from the arguments.
if [[ "$(basename "$0")" == "fbrun" ]]; then
  shift
fi

# Drop the source file name from the arguments to pass the rest to the program.
shift

# Execute the compiled program with the remaining arguments.
"$tempexe" "$@"
