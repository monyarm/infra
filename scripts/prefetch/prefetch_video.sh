#!/usr/bin/env bash
set -euo pipefail

# Usage information
usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [OPTIONS] URL

Prefetch a video using yt-dlp and output its SHA256 hash for use with fetchVideo.

OPTIONS:
    -a, --audio     Download video with audio (default: video only)
    -n, --name NAME Specify a custom name for the video
    -h, --help      Show this help message

EXAMPLES:
    $(basename "$0") "https://youtube.com/watch?v=..."
    $(basename "$0") --audio "https://youtube.com/watch?v=..."
    $(basename "$0") --name "my-video" "https://youtube.com/watch?v=..."
EOF
  exit 1
}

# Parse arguments
AUDIO=false
NAME=""
URL=""

while [[ $# -gt 0 ]]; do
  case $1 in
  -a | --audio)
    AUDIO=true
    shift
    ;;
  -n | --name)
    NAME="$2"
    shift 2
    ;;
  -h | --help)
    usage
    ;;
  *)
    if [[ -z $URL ]]; then
      URL="$1"
    else
      echo "Error: Multiple URLs provided" >&2
      usage
    fi
    shift
    ;;
  esac
done

if [[ -z $URL ]]; then
  echo "Error: URL is required" >&2
  usage
fi

# Determine the filename to use (same logic as fetchVideo)
if [[ -n $NAME ]]; then
  FILENAME="$NAME"
else
  # Try to extract from query parameter (e.g., ?v=sFVJVWVDIMg)
  if [[ $URL =~ [\?\&]v=([^\&]+) ]]; then
    FILENAME="${BASH_REMATCH[1]}"
  # Try to get last path segment (e.g., /video.mp4)
  elif [[ $URL =~ /([^/]+)$ ]]; then
    FILENAME="${BASH_REMATCH[1]}"
  else
    FILENAME="video"
  fi
fi

# Create temporary directory
TMPDIR=$(mktemp -d)
trap 'rm -rf $TMPDIR' EXIT

echo "Downloading video from: $URL" >&2
echo "Filename: $FILENAME" >&2
echo "Audio: $([ "$AUDIO" = true ] && echo "enabled" || echo "disabled")" >&2
echo "" >&2

# Download the video with the correct filename
if [ "$AUDIO" = true ]; then
  yt-dlp -f bestvideo+bestaudio \
    --no-playlist \
    --no-write-subs \
    --no-write-auto-subs \
    --no-write-info-json \
    --no-write-comments \
    -o "$TMPDIR/$FILENAME" \
    "$URL"
else
  yt-dlp -f bestvideo \
    --no-playlist \
    --no-write-subs \
    --no-write-auto-subs \
    --no-write-info-json \
    --no-write-comments \
    -o "$TMPDIR/$FILENAME" \
    "$URL"
fi

# Add to nix store and get hash in SRI format
STORE_PATH=$(nix-store --add-fixed sha256 "$TMPDIR/$FILENAME")
HASH_BASE32=$(nix-hash --type sha256 --base32 --flat "$TMPDIR/$FILENAME")
HASH=$(nix hash to-sri --type sha256 "$HASH_BASE32")

echo "" >&2
echo "Store path: $STORE_PATH" >&2
echo "" >&2
echo "Add this to your Nix file:" >&2
echo "fetchVideo {" >&2
echo "  url = \"$URL\";" >&2
if [[ -n $NAME ]]; then
  echo "  name = \"$NAME\";" >&2
fi
if [ "$AUDIO" = true ]; then
  echo "  audio = true;" >&2
fi
echo "  sha256 = \"$HASH\";" >&2
echo "}" >&2
