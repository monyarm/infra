#!/usr/bin/env bash

# Program: trim.sh
# Notes: Trim trailing linebreaks from the output
# Usage:
#   $ echo -e "a\nb\n\n" | trim
#   > "a\nb"

printf "%s" "$(</dev/stdin)"
