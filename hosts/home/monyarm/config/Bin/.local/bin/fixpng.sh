#!/bin/bash

FIX_COUNT=$(find "$1" -type f -iname '*.png' -print0 | while IFS= read -r -d $'\0' f; do
  WARN=$(pngcrush -n -warn "$f" 2>&1)
  if [[ $WARN == *"PCS illuminant is not D50"* ]] || [[ $WARN == *"known incorrect sRGB profile"* ]]; then
    pngcrush -s -ow -rem allb -reduce "$f"
    echo "FIXED"
  fi
done | grep -c "FIXED")

echo "$FIX_COUNT errors fixed"
