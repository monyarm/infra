#!/bin/bash

PACKAGE_NAME="$1" # Can be "pkg" or "pkg@version"

# Call the common inline progress manager
"$(dirname "$0")"/inline_progress_manager.sh \
  "$PACKAGE_NAME" \
  "npm"

exit $?
