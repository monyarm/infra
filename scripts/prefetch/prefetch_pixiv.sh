#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <pixiv-url>" >&2
  echo "Example: $0 https://i.pximg.net/img-original/img/2025/12/14/15/08/24/138591026_p0.png" >&2
  exit 1
fi

url="$1"

# Get the directory where this script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_root="$(cd "$script_dir/../.." && pwd)"

cd "$nix_root"

nix-prefetch "(import ./lib/fetchers.nix { pkgs = import <nixpkgs> {}; }).fetchPixiv { url = \"$url\"; sha256 = \"\"; }"
