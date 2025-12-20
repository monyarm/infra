#!/bin/bash

# Number of lines to display in the fixed window
N=5

# Array to hold the last N lines
declare -a lines_buffer

# Initialize buffer with empty lines
for ((i = 0; i < N; i++)); do
  lines_buffer[i]=""
done

# Save the initial cursor position. This marks the top of our display window.
tput sc

# Read input line by line from stdin
while IFS= read -r line; do
  # Add the new line to the end of the buffer, and remove the oldest line from the front
  lines_buffer=("${lines_buffer[@]:1}" "$line")

  # Restore the cursor to the saved position (the top of our window)
  tput rc

  # Clear from the current cursor position to the end of the screen.
  # This ensures any previous content (especially if a line became shorter) is removed.
  tput ed

  # Print the current buffer content
  for ((i = 0; i < N; i++)); do
    echo "${lines_buffer[i]}"
  done

  # Optional: A very small delay can sometimes reduce flickering for very fast output,
  # but reading line-by-line often provides natural pacing.
  # sleep 0.01
done
