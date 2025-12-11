#!/usr/bin/env bash
# Exit immediately if a command fails.
set -e

# --- This script converts .iso files to the compressed .cso format using maxcso. ---

usage() {
  echo "Usage: $0 [target_directory]"
  echo "If no directory is provided, this script will process files in the current directory."
  exit 1
}

# --- Main Script ---
# Use the first argument as the target directory, or default to the current directory ('.').
TARGET_DIR="${1:-.}"

# Check if the target directory exists.
if [[ ! -d $TARGET_DIR ]]; then
  echo "Error: Target directory '$TARGET_DIR' not found."
  exit 1
fi

echo "Processing .iso files in: $TARGET_DIR"

# Use a subshell to prevent 'cd' and 'setopt' from affecting the user's current shell.
(
  cd "$TARGET_DIR"
  shopt -s nullglob

  for i in *.iso; do
    echo "Converting '$i'..."
    maxcso "$i" --use-libdeflate --block=32768 --format=cso1 --use-zopfli -o "${i%.iso}.cso"
  done
)

echo "Conversion process complete."
