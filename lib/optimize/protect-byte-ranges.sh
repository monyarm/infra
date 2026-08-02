#!/usr/bin/env bash
# Runs an arbitrary transform command over a file, except for byte ranges
# that follow a marker line -- those are copied through completely
# untouched. For formats like DeHackEd's "Text <fromLen> <toLen>" blocks,
# whose replacement text is raw, length-prefixed content that a line-based
# transform (comment/blank-line stripping) must never touch.
#
# Usage: protect-byte-ranges.sh MARKER_REGEX INFILE OUTFILE -- TRANSFORM...
# MARKER_REGEX: a gawk regex whose capture groups are summed for the byte
# count of the raw content immediately following a matching line.
set -euo pipefail

marker_regex="$1"
infile="$2"
outfile="$3"
shift 3
if [ "${1:-}" = "--" ]; then
  shift
fi

ranges="$(mktemp)"
trap 'rm -f "$ranges"' EXIT

# One "<start> <length>" pair per matched marker line, byte-counted.
gawk -v regex="$marker_regex" '
{
  line = $0
  nbytes = length(line) + 1
  if (match(line, regex, m)) {
    len = 0
    for (i = 1; i in m; i++) len += m[i]
    print offset + nbytes, len
  }
  offset += nbytes
}
' "$infile" > "$ranges"

: > "$outfile"
pos=0
while read -r start len; do
  safe_len=$((start - pos))
  if [ "$safe_len" -gt 0 ]; then
    tail -c +"$((pos + 1))" "$infile" | head -c "$safe_len" | "$@" >> "$outfile" || [ "$?" = 1 ]
  fi
  tail -c +"$((start + 1))" "$infile" | head -c "$len" >> "$outfile"
  pos=$((start + len))
done < "$ranges"

tail -c +"$((pos + 1))" "$infile" | "$@" >> "$outfile" || [ "$?" = 1 ]
