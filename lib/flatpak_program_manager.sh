#!/bin/bash

# Takes a single Flatpak ID (e.g., org.mozilla.firefox:flathub)
RAW_FLATPAK_ID="$1"

# Call the common inline progress manager
"$(dirname "$0")"/inline_progress_manager.sh \
  "$RAW_FLATPAK_ID" \
  "flatpak"

exit $?
