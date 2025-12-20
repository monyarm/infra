#!/bin/bash

REPO_NAME="$1"
REPO_URL="$2"
LOG_FILE="/tmp/flatpak_remote_${REPO_NAME}_$(date +%Y%m%d%H%M%S).log"

# Helper function to print status on a single line
print_status() {
  local message="$1"
  echo -ne "\r\033[K$message"
}

# --- Main Logic ---

print_status "\033[35m${REPO_NAME}\033[0m:\tChecking remote status..."

# Check if remote already exists
if sudo /usr/bin/flatpak remote-list | grep -q -F -x "${REPO_NAME}"; then
  print_status "\033[35m${REPO_NAME}\033[0m:\tAlready added\n"
  exit 0
fi

print_status "\033[35m${REPO_NAME}\033[0m: Adding remote..."

# Add the remote
sudo /usr/bin/flatpak remote-add --if-not-exists "${REPO_NAME}" "${REPO_URL}" 2>&1 | tee "$LOG_FILE" >/dev/null
ADD_STATUS=$?

if [ $ADD_STATUS -eq 0 ]; then
  print_status "\033[35m${REPO_NAME}\033[0m:\tAdded\n"
else
  print_status "\033[35m${REPO_NAME}\033[0m:\t\033[31mError...\033[0m Log: ${LOG_FILE}\n"
fi
