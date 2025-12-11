#!/usr/bin/bash

# Function to process a single file
process_file() {
  local file="$1"
  shellcheck -f diff "$file" | git apply --allow-empty
}

# Function to process a directory
process_directory() {
  local dir="$1"
  find "$dir" \
    \( -path '*/node_modules' -o -path '*/bundle' -o -path '*/vendor' \) -prune -o \
    -type f \( -iname '*.sh' -o -iname '*.zsh' \) -print0 |
    xargs -0 shellcheck -f diff | git apply --allow-empty
}

# Main loop to handle arguments
for arg in "$@"; do
  if [ -f "$arg" ]; then
    process_file "$arg"
  elif [ -d "$arg" ]; then
    process_directory "$arg"
  else
    echo "Warning: '$arg' is not a valid file or directory. Skipping." >&2
  fi
done
