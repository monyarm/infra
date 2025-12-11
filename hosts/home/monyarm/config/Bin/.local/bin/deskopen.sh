#!/bin/bash
# Exit immediately on error and treat unset variables as an error.
set -eu

# --- This script launches an application from a .desktop file. ---
# It extracts and executes the 'Exec' command from the given file.

usage() {
  echo "Usage: $0 <path_to_desktop_file>"
  exit 1
}

# --- Main Script ---
# Check for the correct number of arguments.
if [[ $# -ne 1 ]]; then
  usage
fi

DESKTOP_FILE="$1"
if [[ ! -f $DESKTOP_FILE ]]; then
  echo "Error: File not found: '$DESKTOP_FILE'"
  exit 1
fi

# Use sed to find the 'Exec' line and clean it up in one go.
# - e 's/^Exec=//': Removes 'Exec=' from the beginning.
# - e 's/ %[a-zA-Z]//g': Removes desktop-specific field codes (like %f, %u, %i).
# - e 's/^"//; s/"$//': Removes leading and trailing quotes.
exec_line=$(grep '^Exec' "$DESKTOP_FILE" | tail -1 | sed -e 's/^Exec=//' -e 's/ %[a-zA-Z]//g' -e 's/^"//; s/"$//')

if [[ -z $exec_line ]]; then
  echo "Error: Could not find a valid 'Exec' line in '$DESKTOP_FILE'."
  exit 1
fi

echo "Executing: $exec_line"
# Use 'eval' to correctly handle commands that may contain quotes and arguments.
# The command is run in the background with '&''.
eval "$exec_line" &
