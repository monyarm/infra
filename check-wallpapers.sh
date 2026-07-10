#!/usr/bin/env bash
# check-wallpapers.sh: Verifies Minecraft wallpaper zip contents against Nix definitions.

set -euo pipefail

# 1. Locate the minecraft.nix file
NIX_FILE="hosts/home/monyarm/config/Backgrounds/wallpapers/games/minecraft.nix"
if [ ! -f "$NIX_FILE" ]; then
  # Try to find it in the current directory tree
  FOUND_FILE=$(find . -name "minecraft.nix" | head -n 1)
  if [ -n "$FOUND_FILE" ]; then
    NIX_FILE="$FOUND_FILE"
  fi
fi

if [ ! -f "$NIX_FILE" ]; then
  echo "Error: Could not find minecraft.nix in hosts/home/monyarm/config/Backgrounds/wallpapers/games/minecraft.nix or anywhere in the current tree." >&2
  exit 1
fi

echo "Using Nix file: $NIX_FILE"

# 2. Evaluate Nix definitions to JSON
echo "Evaluating Nix definitions..."
MOCK_EXPR='import '"$NIX_FILE"' { pkgs = { fetchzip = { url, ... }: "MOCK_URL:${url}#MOCK_FILE:"; runCommand = name: env: cmd: "MOCK_URL:${env.meta.url}#MOCK_FILE:${env.meta.expected_filename}"; unzip = null; }; }'
if ! JSON_DATA=$(nix-instantiate --eval --strict --json -E "$MOCK_EXPR" 2>/dev/null); then
  echo "Error: Failed to evaluate Nix file. Make sure nix-instantiate is available." >&2
  exit 1
fi

# 3. Create temporary directory
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

keys=$(echo "$JSON_DATA" | jq -r 'keys[]')
total_keys=$(echo "$keys" | wc -l)
current=0
broken_count=0
ok_count=0
failed_count=0

broken_reports=()
failed_reports=()

echo "Checking $total_keys wallpapers..."
echo "========================================"

for key in $keys; do
  current=$((current + 1))
  value=$(echo "$JSON_DATA" | jq -r ".\"$key\"")

  # Parse URL and expected filename using our custom delimiters
  url_part="${value#MOCK_URL:}"
  url="${url_part%%#MOCK_FILE:*}"
  expected_filename_part="${url_part#*#MOCK_FILE:}"
  expected_filename="${expected_filename_part#/}" # Strip leading slash if any

  echo -n "[$current/$total_keys] $key: "

  zip_file="$TMP_DIR/${key}.zip"

  # Download zip using curl
  if ! curl -s -f -A "Mozilla" -L "$url" -o "$zip_file"; then
    echo "FAILED (Download failed)"
    failed_count=$((failed_count + 1))
    failed_reports+=("$key | URL: $url")
    continue
  fi

  # Check for nested zip verification (e.g. wildUpdate)
  if [[ $expected_filename == *".zip/"* ]]; then
    inner_zip_name="${expected_filename%%.zip/*}.zip"
    inner_expected="${expected_filename#*/}"

    # Extract the inner zip to a temp location
    mkdir -p "$TMP_DIR/nested"
    unzip -q -j "$zip_file" "$inner_zip_name" -d "$TMP_DIR/nested" 2>/dev/null || true
    inner_zip_file="$TMP_DIR/nested/$inner_zip_name"

    if [ -f "$inner_zip_file" ]; then
      # Extract resolution from expected name
      res=$(echo "$inner_expected" | grep -oE "[0-9]+x[0-9]+" || echo "1920x1080")
      if [ -z "$res" ]; then res="1920x1080"; fi

      actual_path=$(unzip -Z -1 "$inner_zip_file" 2>/dev/null | grep -E "${res}\.png$" | head -n 1 | tr -d '\r' || true)
      if [ -z "$actual_path" ]; then
        actual_path=$(unzip -Z -1 "$inner_zip_file" 2>/dev/null | grep "$res" | head -n 1 | tr -d '\r' || true)
      fi

      inner_expected_base=$(basename "$inner_expected")
      if [ "$actual_path" = "$inner_expected_base" ]; then
        echo "OK"
        ok_count=$((ok_count + 1))
      else
        echo "BROKEN"
        echo "  Expected: $inner_expected_base"
        echo "  Actual:   $actual_path"
        broken_count=$((broken_count + 1))
        broken_reports+=("$key | Expected: $inner_expected_base | Actual: $actual_path")
      fi
    else
      echo "FAILED (Could not extract inner zip $inner_zip_name)"
      failed_count=$((failed_count + 1))
      failed_reports+=("$key | Inner zip $inner_zip_name not found")
    fi
    rm -rf "$TMP_DIR/nested"
    continue
  fi

  # Extract resolution from expected name (e.g. 1920x1080, 2058x1440, etc.)
  res=$(echo "$expected_filename" | grep -oE "[0-9]+x[0-9]+" || echo "1920x1080")
  if [ -z "$res" ]; then res="1920x1080"; fi

  # Standard non-nested zip verification
  actual_path=$(unzip -Z -1 "$zip_file" 2>/dev/null | grep -E "${res}\.png$" | head -n 1 | tr -d '\r' || true)
  if [ -z "$actual_path" ]; then
    actual_path=$(unzip -Z -1 "$zip_file" 2>/dev/null | grep "$res" | head -n 1 | tr -d '\r' || true)
  fi

  if [ -z "$actual_path" ]; then
    echo "FAILED (No $res file found inside zip)"
    failed_count=$((failed_count + 1))
    failed_reports+=("$key | No $res file found in zip")
    continue
  fi

  # Compare paths
  if [ "$actual_path" = "$expected_filename" ]; then
    echo "OK"
    ok_count=$((ok_count + 1))
  else
    echo "BROKEN"
    echo "  Expected: $expected_filename"
    echo "  Actual:   $actual_path"
    broken_count=$((broken_count + 1))
    broken_reports+=("$key | Expected: $expected_filename | Actual: $actual_path")
  fi
done

echo -e "\n========================================"
echo -e "                SUMMARY"
echo -e "========================================"
echo -e "Total checked: $total_keys"
echo -e "OK:            $ok_count"
echo -e "Broken:        $broken_count"
echo -e "Failed:        $failed_count"
echo -e "========================================"

if [ "$broken_count" -gt 0 ]; then
  echo -e "\nBroken Wallpapers:"
  for report in "${broken_reports[@]}"; do
    echo -e "  - $report"
  done
fi

if [ "$failed_count" -gt 0 ]; then
  echo -e "\nFailed Downloads/Checks:"
  for report in "${failed_reports[@]}"; do
    echo -e "  - $report"
  done
fi

exit $broken_count
