#!/usr/bin/env bash

# Configuration
MAX_CONSECUTIVE_CONNECTION_FAILURES=2
RETRY_DELAY=30

CONSECUTIVE_CONNECTION_FAILURES=0
LOG_FILE="/tmp/build-retry-$$.log"

if [ $# -eq 0 ]; then
  echo "Usage: $0 <build-command> [args...]"
  echo "Example: $0 nix build .#mypackage"
  exit 1
fi

while true; do
  # Clear the log file
  echo "" >"$LOG_FILE"

  echo Running: "$@"
  "$@" 2>&1 | tee "$LOG_FILE"
  exit_code=${PIPESTATUS[0]}

  if [ "$exit_code" -eq 0 ]; then
    echo "Build successful!"
    rm -f "$LOG_FILE"
    exit 0
  fi

  # Check for hash mismatch error
  specified=$(grep "specified:" "$LOG_FILE" | sed -n 's/.*sha256-\([A-Za-z0-9+/=]*\).*/\1/p')
  got=$(grep "got:" "$LOG_FILE" | sed -n 's/.*sha256-\([A-Za-z0-9+/=]*\).*/\1/p')

  if [ -n "$specified" ] && [ -n "$got" ]; then
    echo "Hash mismatch detected!"
    echo "  specified: sha256-$specified"
    echo "  got:       sha256-$got"

    # Replace in all .nix files in current directory and subdirectories
    find . -name "*.nix" -type f -exec sed -i "s|sha256-$specified|sha256-$got|g" {} +
    echo "Hash replaced. Retrying..."

    # Reset connection failure counter
    CONSECUTIVE_CONNECTION_FAILURES=0
    continue
  fi

  # Check for connection error
  if grep -q "curl: (35) Recv failure: Connection reset by peer" "$LOG_FILE"; then
    CONSECUTIVE_CONNECTION_FAILURES=$((CONSECUTIVE_CONNECTION_FAILURES + 1))
    echo "Connection error detected (attempt $CONSECUTIVE_CONNECTION_FAILURES/$((MAX_CONSECUTIVE_CONNECTION_FAILURES + 1)))"

    if [ "$CONSECUTIVE_CONNECTION_FAILURES" -gt "$MAX_CONSECUTIVE_CONNECTION_FAILURES" ]; then
      echo "Failed $MAX_CONSECUTIVE_CONNECTION_FAILURES times with connection error. Giving up."
      echo ""
      echo "Last build output:"
      cat "$LOG_FILE"
      rm -f "$LOG_FILE"
      exit 1
    fi

    echo "Waiting $RETRY_DELAY seconds before retrying..."
    sleep $RETRY_DELAY
    continue
  fi

  # Any other error - give up
  echo "Build failed with non-recoverable error:"
  echo ""
  cat "$LOG_FILE"
  rm -f "$LOG_FILE"
  exit 1
done
