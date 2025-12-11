#!/usr/bin/env bash
# Exit immediately if a command fails.
set -e

# --- This script converts various disc image formats to the CHD format. ---
# It processes .cue, .gdi, and .iso files in the specified or current directory.

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

echo "Processing files in: $TARGET_DIR"

# Use 'setopt' to handle globbing within a subshell to avoid affecting the user's shell.
(
  cd "$TARGET_DIR"
  shopt -s nullglob

  echo "--- Processing CD images (.cue, .gdi, .chd) ---"
  for i in *.{cue,gdi,chd}; do
    echo "Converting '$i'..."
    chdman createcd -i "$i" -o "${i%.*}.chd"
  done

  echo "--- Processing DVD images (.iso) ---"
  for i in *.iso; do
    echo "Converting '$i'..."
    chdman createdvd -i "$i" -o "${i%.*}.chd"
  done
)

echo "Conversion process complete."
