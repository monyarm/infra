#!/bin/bash
# Exit immediately on error and treat unset variables as an error.
set -eu

# --- This script reads a list of URLs from a file, curls them, and logs the results. ---

# --- Configuration ---
TIMEZONE="Europe/Zurich"
# To enable email notifications, uncomment the following line and set your email address.
# MAIL_TO="your@email.com"

# --- Functions ---
usage() {
  echo "Usage: $0 <path_to_urls_file>"
  exit 1
}

log() {
  # Logs a message to both stdout and the log file.
  local message="$1"
  local timestamp
  timestamp=$(TZ=":$TIMEZONE" date)
  # Using 'tee' to append to the log file while also printing to the console.
  echo "$timestamp $message" | tee -a "$LOG_FILE"
}

# --- Main Script ---
# Check for the correct number of arguments.
if [[ $# -ne 1 ]]; then
  usage
fi

URL_FILE="$1"
if [[ ! -f $URL_FILE ]]; then
  echo "Error: URL file not found at '$URL_FILE'"
  exit 1
fi

# Set up the log file name based on the script's name.
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="${SCRIPT_NAME%.*}.log"

log "[INFO] Starting URL crawl."
log "[INFO] Reading URLs from: $URL_FILE"

# Process the URL file, redirecting the file to the 'while' loop.
# This is more efficient and safer than 'cat ... | while'.
while IFS= read -r url || [[ -n $url ]]; do
  # Skip empty lines.
  if [[ -z $url ]]; then
    continue
  fi

  log "[INFO] Crawling URL: $url"
  start_time=$(date +%s)

  # Perform the curl request.
  # The result includes the HTTP status code and the effective URL after redirects.
  curl_result=$(curl -sSL -w '%{http_code} %{url_effective}' "$url" -o /dev/null)

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  log "[INFO] Result: $curl_result"
  log "[INFO] Crawl time: $duration seconds."

done <"$URL_FILE"

log "[INFO] Finished processing all URLs."

# Send an email notification if the MAIL_TO variable is set.
if [[ -n ${MAIL_TO-} ]]; then
  log "[INFO] Sending email notification to: $MAIL_TO"
  mail_subject="$SCRIPT_NAME log from $(TZ=":$TIMEZONE" date)"
  if ! mail -s "$mail_subject" "$MAIL_TO" <"$LOG_FILE"; then
    log "[ERROR] Failed to send email notification."
  fi
fi

log "[INFO] Crawl complete."
exit 0
