#!/bin/bash
# Exit immediately on error and treat unset variables as an error.
set -eu

# --- This script spiders a website to generate a clean list of unique URLs. ---

# --- Configuration & Style ---
# The default location where the URL list will be saved.
DEFAULT_SAVE_LOCATION="$HOME/Desktop"
# You can change this to a different directory, e.g., "/tmp" or "."
SAVE_LOCATION="${DEFAULT_SAVE_LOCATION}"

# Color definitions for output messages.
COLOR_RED='\e[31m'
COLOR_CYAN='\e[36m'
COLOR_YELLOW='\e[93m'
COLOR_GREEN='\e[32m'
COLOR_RESET='\e[0m'

# --- Functions ---
# A spinner function to show that the script is working.
display_spinner() {
  local pid=$1
  local delay=0.2
  # shellcheck disable=SC1003 # No, I'm not escaping a '
  local spinstr='|/-\\'
  while ps -p "$pid" >/dev/null; do
    printf "${COLOR_RESET}#    ${COLOR_YELLOW}Please wait... [%c]  ${COLOR_RESET}" "$spinstr"
    spinstr=${spinstr:1}${spinstr:0:1} # Rotate the spinner
    sleep "$delay"
    printf "\r" # Return to the beginning of the line
  done
  printf "                                        \r" # Clear the line
}

# The main function to fetch and filter URLs.
fetch_site_urls() {
  local domain="$1"
  local output_file="$2"

  echo "#    Fetching URLs. This may take a while..."

  # A single, multi-line awk command is more efficient than a long chain of greps.
  # It filters out unwanted URLs based on a series of patterns.
  wget --spider -r -nd --max-redirect=30 "$domain" 2>&1 |
    grep '^--' |
    awk '{ print $3 }' |
    awk '
            !/\.(css|js|map|xml|png|gif|jpg|JPG|bmp|txt|pdf)(\?.*)?$/ && \
            !/\?(p|replytocom)=/ && \
            !/\/wp-content\/uploads\// && \
            !/\/feed\// && \
            !/\/category\// && \
            !/\/tag\// && \
            !/\/page\// && \
            !/\/widgets\.php$/ && \
            !/\/wp-json\// && \
            !/\/xmlrpc/
        ' |
    sort -u \
      >"$output_file"
}

# --- Main Script ---
# Check if wget is installed.
if ! command -v wget &>/dev/null; then
  echo -e "${COLOR_RED}#    Error: 'wget' is not installed. Please install it to continue.${COLOR_RESET}"
  exit 1
fi

# --- User Interaction ---
echo -e "${COLOR_RESET}#\n#    Fetch a list of unique URLs for a domain.\n#"
read -r -p "#    Enter the full URL (e.g., http://example.com): ${COLOR_CYAN}" DOMAIN
DOMAIN="${DOMAIN%/}" # Remove trailing slash

# Generate default filename from the domain.
display_domain=$(echo "$DOMAIN" | grep -oP "^https?://(www\.)?\K.*")
default_filename=$(echo "$display_domain" | tr '.' '-')

echo -e "${COLOR_RESET}#"
read -r -p "#    Enter a filename for the saved URL list: ${COLOR_CYAN}" -i "${default_filename}" SAVE_FILENAME
echo -e "${COLOR_RESET}#"

# Expand the tilde to the full home directory path.
eval expanded_save_location="$SAVE_LOCATION"
OUTPUT_FILE="$DEFAULT_SAVE_LOCATION/$SAVE_FILENAME.txt"

# --- Execution ---
# Run the fetch function in the background so the spinner can run.
fetch_site_urls "$DOMAIN" "$OUTPUT_FILE" &
# Get the Process ID (PID) of the backgrounded function.
fetch_pid=$!

# Display the spinner while the fetch function is running.
display_spinner "$fetch_pid"

# Wait for the fetch process to complete and check its exit code.
if ! wait "$fetch_pid"; then
  echo -e "${COLOR_RED}#    Error during URL fetching. Check the output above.${COLOR_RESET}"
  exit 1
fi

# --- Results ---
# Count the number of non-empty lines in the output file.
result_count=$(grep -c . "$OUTPUT_FILE" || true)
result_message="${result_count} Result"
[[ $result_count -ne 1 ]] && result_message="${result_count} Results"

echo -e "${COLOR_RESET}#\n#    ${COLOR_GREEN}Finished with ${result_message}!${COLOR_RESET}\n#"
echo -e "#    ${COLOR_GREEN}File Location:${COLOR_RESET}"
echo -e "#    ${COLOR_GREEN}${OUTPUT_FILE}${COLOR_RESET}\n#"

exit 0
