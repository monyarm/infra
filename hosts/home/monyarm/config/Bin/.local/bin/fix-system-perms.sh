#!/bin/bash

# --- Paths Definition (CORRECTED for Expansion) ---
# Brace expansion is done by the shell before assignment.
# To ensure 'find' gets the correct directories, we must explicitly list them
# in an array, which is the safest way to pass multi-word arguments.
declare -a SEARCH_PATHS=(
  /bin
  /lib
  /lib64
  /usr/bin
  /usr/lib
  /usr/lib64
  /usr/share
  /usr/include
  /opt
)

# --- Superuser Command Detection ---

# Check if the script is running as root
if [ "$EUID" -eq 0 ]; then
  SUDO=""
else
  # Check for available superuser commands: sudo then doas
  if command -v sudo &>/dev/null; then
    SUDO="sudo"
  elif command -v doas &>/dev/null; then
    SUDO="doas"
  else
    echo "Error: Not running as root, and 'sudo' or 'doas' is not available." >&2
    echo "Please install a superuser utility or run the script as root." >&2
    exit 1
  fi
fi

# Initialize a counter for the fixed files
FIXED_COUNT=0
# Use a temporary file to store the list of files found by find
TEMP_FILE=$(mktemp)
# Ensure the temporary file is deleted on exit
trap "rm -f ""$TEMP_FILE""" EXIT

# Inform the user which superuser command is being used
if [ -n "$SUDO" ]; then
  echo "Using '$SUDO' for privileged commands."
fi

# 1. FIND: Locate all files that meet the criteria and store them in the temporary file.
echo "Searching for files owned by root and missing owner read permission."
echo "Paths:" "${SEARCH_PATHS[@]}"

# Use the array expansion "${SEARCH_PATHS[@]}" to pass all paths correctly
# as separate arguments to the find command.
$SUDO find "${SEARCH_PATHS[@]}" -type f -user root ! -perm /u=r -print0 >"$TEMP_FILE"

# Check if find returned any files
if [ ! -s "$TEMP_FILE" ]; then
  echo "No files found requiring permission fixes. Exiting."
  # The trap command will clean up the temp file
  exit 0
fi

# 2. FIX and COUNT: Read the files from the temp file, print them, and count.
echo "---"
echo "Fixing permissions (adding owner read permission):"

# Loop safely over the null-separated filenames
while IFS= read -r -d $'\0' FILE; do
  echo "  -> Fixing: $FILE"
  # Execute chmod +r for the file
  $SUDO chmod +r "$FILE"
  # Increment the counter
  FIXED_COUNT=$((FIXED_COUNT + 1))
done <"$TEMP_FILE"

# 3. SUMMARY: Print the final count
echo "---"
echo "Operation complete."
echo "A total of $FIXED_COUNT file(s) had read permission added for the owner."
