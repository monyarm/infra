#!/bin/bash

PACKAGE_NAME="$1"

# Call the common inline progress manager
"$(dirname "$0")"/inline_progress_manager.sh \
  "$PACKAGE_NAME" \
  "cargo"

exit $?
