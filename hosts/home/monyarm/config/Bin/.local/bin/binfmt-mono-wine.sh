#!/bin/bash
# Exit immediately on error, treat unset variables as an error, and handle pipeline failures.
set -euo pipefail

# --- This script runs a file with '''mono''' or '''wine''' based on its format. ---
# It relies on '''binfmt-detector-cli''' being available in the system'''s PATH.

# Function to display usage information.
usage() {
  echo "Usage: $0 <executable_file>"
  exit 1
}

# --- Main Script ---
# Ensure a file has been provided.
if [[ $# -eq 0 ]]; then
  usage
fi

# Check if the required '''binfmt-detector-cli''' command is available.
if ! command -v binfmt-detector-cli &>/dev/null; then
  echo "Error: '''binfmt-detector-cli''' command not found in your PATH."
  exit 1
fi

# Use the detector to decide whether to use '''mono''' or '''wine'''.
if binfmt-detector-cli "$1"; then
  # The detector returned success (exit code 0), so use mono.
  mono "$@"
else
  # The detector returned failure (non-zero exit code), so use wine.
  wine "$@"
fi
