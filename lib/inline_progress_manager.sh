#!/bin/bash

# This script provides inline progress updates for installation commands.
# It takes the program ID (package name) and the program type (e.g., "cargo", "npm", "flatpak").

PROGRAM_ID="$1"
PROGRAM_TYPE="$2"

# --- Configuration ---
LOG_FILE_BASE="/tmp/${PROGRAM_TYPE}_manager_${PROGRAM_ID//[^a-zA-Z0-9_.-]/_}"
LOG_FILE="${LOG_FILE_BASE}.log"

# --- Utility Functions ---

# Function to get the CURRENT_VERSION / NEW_VERSION for various program types
get_version_for_type() {
  local pkg_id="$1"
  local pkg_type="$2"
  local version=""

  case "$pkg_type" in
  "cargo")
    # More robust parsing for cargo
    version=$(cargo install --list 2>/dev/null |
      grep -E "^${pkg_id} v" |
      head -n 1 |
      sed -E 's/^[^v]*v([0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\.-]+)?).*$/\1/')
    ;;
  "npm")
    if [[ $pkg_id == "npm" ]]; then
      # Special case: get the version of npm itself.
      version=$(npm --version 2>/dev/null)
    else
      local base_package_name
      base_package_name=$(echo "$pkg_id" | sed -E 's/(@?[^@]+)@?.*/\1/')
      version=$(npm list -g --depth=0 --json 2>/dev/null | jq -r ".dependencies.\"$base_package_name\".version // empty")
    fi
    ;;
  "flatpak")
    local raw_flatpak_id="$pkg_id"
    local flatpak_id
    if [[ $raw_flatpak_id == *":"* ]]; then
      flatpak_id=$(echo "$raw_flatpak_id" | cut -d':' -f1)
    else
      flatpak_id="$raw_flatpak_id"
    fi
    # Get the installed version by listing apps and finding the matching ID
    version=$(sudo /usr/bin/flatpak list --app --columns=application,version 2>/dev/null |
      grep -E "^${flatpak_id}[[:space:]]" |
      awk '{print $2}')
    ;;
  esac
  echo "$version"
}

# Function to update the current line in the terminal
update_inline_status() {
  local prefix="$1"
  local message="$2"
  local term_width
  # Get terminal width, default to 80 if tput fails
  term_width=$(tput cols 2>/dev/null || echo 80)

  # Calculate the length of the prefix, stripping ANSI codes for an accurate count.
  # A tab is 8 chars, but we'll be conservative and use 4 to be safe.
  local prefix_len
  prefix_len=$(echo -e "$prefix" | sed 's/\x1b\[[0-9;]*m//g' | wc -c)

  local available_width=$((term_width - prefix_len))

  # If the message is longer than the terminal width, truncate it.
  if ((${#message} > available_width)); then
    # Truncate message to fit, leaving space for "..."
    message=$(printf "%.*s" "$((available_width - 3))" "$message")"..."
  fi

  echo -ne "\r\033[K${prefix}${message}"
}

# --- Main Logic ---

# Initial Status and Version Check
CURRENT_VERSION=$(get_version_for_type "$PROGRAM_ID" "$PROGRAM_TYPE")
install_command_exit_status=1
install_success=0

if [ -z "$CURRENT_VERSION" ]; then
  INITIAL_MESSAGE="\033[35m${PROGRAM_ID}\033[0m:\tInstalling..."
else
  INITIAL_MESSAGE="\033[35m${PROGRAM_ID}\033[0m:\tChecking for updates (current \033[33m${CURRENT_VERSION}\033[0m)..."
fi

update_inline_status "$INITIAL_MESSAGE"

case "$PROGRAM_TYPE" in
"cargo")
  (
    if [ -z "$CURRENT_VERSION" ]; then
      unbuffer cargo install "${PROGRAM_ID}" 2>&1
    else
      unbuffer cargo update --locked --workspace "${PROGRAM_ID}" 2>&1 || unbuffer cargo install "${PROGRAM_ID}" 2>&1
    fi
  ) | while IFS= read -r line; do
    #if echo "$line" | grep -E -q "$PROGRESS_PATTERN"; then
    #  stripped_line=$(echo "$line" | tr -d '\n')
    #fi
    echo "$line" >>"$LOG_FILE"
  done

  install_command_exit_status=${PIPESTATUS[0]}
  ;;
"npm")
  #PROGRESS_PATTERN="^npm |[[:space:]]*[0-9]+%|.*[=->].*"
  #SUCCESS_PATTERN="up to date"

  (
    if [[ $PROGRAM_ID == "npm" || $PROGRAM_ID == npm@* ]]; then
      # Special case for npm itself: always run update.
      npm update -g --force --verbose --color=false "npm" 2>&1
    else
      # For all other packages, check if installed, then decide to install or update.
      base_package_name=$(echo "$PROGRAM_ID" | sed -E 's/(@?[^@]+)@?.*/\1/')
      if ! npm list -g --depth=0 2>/dev/null | grep -q -E "^.. ${base_package_name}@"; then
        npm install -g --verbose --color=false "${PROGRAM_ID}" 2>&1
      else
        npm update -g --force --verbose --color=false "${base_package_name}" 2>&1
      fi
    fi
  ) | while IFS= read -r line; do
    #if echo "$line" | grep -E -q "$PROGRESS_PATTERN"; then
    #  stripped_line=$(echo "$line" | tr -d '\n' | tr -d '\r')
    #fi
    echo "$line" >>"$LOG_FILE"
  done

  install_command_exit_status=${PIPESTATUS[0]}
  ;;
"flatpak")
  #PROGRESS_PATTERN="^[[:space:]]*[0-9]+\\.\\s.*|Downloading|Installing|Updating|\[/\]|\[\\\\]"
  #SUCCESS_PATTERN="already installed|up to date|is already installed|is up to date"

  raw_flatpak_id="$PROGRAM_ID"
  flatpak_id=""
  repo="flathub"
  if [[ $raw_flatpak_id == *":"* ]]; then
    flatpak_id=$(echo "$raw_flatpak_id" | cut -d':' -f1)
    repo=$(echo "$raw_flatpak_id" | cut -d':' -f2)
  else
    flatpak_id="$raw_flatpak_id"
  fi

  (sudo /usr/bin/flatpak install -y --or-update "$repo" "$flatpak_id" 2>&1) | while IFS= read -r line; do
    #if echo "$line" | grep -E -q "$PROGRESS_PATTERN"; then
    #  stripped_line=$(echo "$line" | tr -d '\n')
    #fi
    echo "$line" >>"$LOG_FILE"
  done

  install_command_exit_status=${PIPESTATUS[0]}
  ;;
*)
  update_inline_status "\033[31mError: Unknown PROGRAM_TYPE: $PROGRAM_TYPE\033[0m\n"
  exit 1
  ;;
esac

# Determine INSTALL_SUCCESS
if [ "$install_command_exit_status" -eq 0 ]; then
  install_success=1
fi

# Final status for this program
if [ $install_success -eq 1 ]; then
  NEW_VERSION=$(get_version_for_type "$PROGRAM_ID" "$PROGRAM_TYPE")

  FINAL_MESSAGE=""
  if [ -z "$CURRENT_VERSION" ]; then
    FINAL_MESSAGE="\033[35m${PROGRAM_ID}\033[0m:\tInstalled \033[32m${NEW_VERSION}\033[0m"
  elif [ "$CURRENT_VERSION" == "$NEW_VERSION" ]; then
    FINAL_MESSAGE="\033[35m${PROGRAM_ID}\033[0m:\tAlready installed \033[33m${CURRENT_VERSION}\033[0m"
  else
    FINAL_MESSAGE="\033[35m${PROGRAM_ID}\033[0m:\tUpdated \033[32m${CURRENT_VERSION}\033[0m -> \033[32m${NEW_VERSION}\033[0m"
  fi
  update_inline_status "${FINAL_MESSAGE}\n"
  exit 0
else
  update_inline_status "\033[35m${PROGRAM_ID}\033[0m:\t\033[31mError\033[0m. Log: ${LOG_FILE}\n"
  exit 1
fi
