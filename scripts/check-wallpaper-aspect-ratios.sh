#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir=${1:-"${HOME}/Pictures/wallpapers"}
tolerance_percent=${RATIO_TOLERANCE_PERCENT:-1}

if [[ ! -d ${wallpaper_dir} ]]; then
  printf 'Wallpaper directory does not exist: %s\n' "${wallpaper_dir}" >&2
  exit 2
fi

if command -v identify >/dev/null 2>&1; then
  identify_command=(identify)
elif command -v magick >/dev/null 2>&1; then
  identify_command=(magick identify)
else
  printf 'ImageMagick is required (identify or magick).\n' >&2
  exit 2
fi

if ! [[ ${tolerance_percent} =~ ^[0-9]+$ ]]; then
  printf 'RATIO_TOLERANCE_PERCENT must be a non-negative integer.\n' >&2
  exit 2
fi

outliers=0
errors=0
files=0

while IFS= read -r -d '' file; do
  dimensions=$("${identify_command[@]}" -format '%w %h' -- "${file}" 2>/dev/null || true)
  if [[ ${dimensions} != [0-9]*\ [0-9]* ]] || [[ ${dimensions} =~ [^0-9[:space:]] ]]; then
    printf 'Unable to read image dimensions: %s\n' "${file}" >&2
    errors=$((errors + 1))
    continue
  fi

  read -r width height <<<"${dimensions}"
  files=$((files + 1))

  difference=$((width * 9 - height * 16))
  ((difference < 0)) && difference=$((-difference))
  reference=$((width * 9))
  ((height * 16 > reference)) && reference=$((height * 16))

  if ((difference * 100 > reference * tolerance_percent)); then
    ratio=$(awk -v width="${width}" -v height="${height}" 'BEGIN { printf "%.5f", width / height }')
    printf 'OUTLIER %sx%s (ratio %s): %s\n' "${width}" "${height}" "${ratio}" "${file}"
    outliers=$((outliers + 1))
  fi
done < <(find -L "${wallpaper_dir}" -type f -print0)

printf 'Checked %d images; %d outliers; %d unreadable files; tolerance %d%%.\n' \
  "${files}" "${outliers}" "${errors}" "${tolerance_percent}"

((outliers == 0 && errors == 0))
