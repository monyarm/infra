#!/usr/bin/env bash
# Usage: prefetchSteamCards --appId <appid> [--cardNames "card1,card2,..."]

set -e

while [[ $# -gt 0 ]]; do
  case $1 in
  --appId)
    appId="$2"
    shift 2
    ;;
  --cardNames)
    cardNames="$2"
    shift 2
    ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

if [[ -z $appId ]]; then
  echo "Missing --appId argument" >&2
  exit 1
fi

# 1. Formulate the Nix expression evaluating your fetcher directly
fetcher_expr="(import ./lib/fetchers.nix { pkgs = import <nixpkgs> { }; dirs = null; importSopsString = null; urlEncode = x: x; }).fetchSteamCards {
  appId = ${appId};
  ${cardNames:+cardNames = [ "${cardNames//,/\" \"}" ];}
  sha256 = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";
}"

echo "Evaluating and fetching (this will intentionally fail with a hash mismatch)..."

# 2. Use nix-build instead of nix-prefetch
# We redirect stderr to capture the hash mismatch printout
set +e
output=$(nix-build -E "$fetcher_expr" --no-out-link 2>&1)
set -e

# 3. Extract the got/specified hashes from the error message
if echo "$output" | grep -q "hash mismatch"; then
  echo "---"
  echo "Successfully fetched! Copy the 'got:' hash below:"
  echo "$output" | grep -A 3 "hash mismatch"
else
  echo "An unexpected error occurred:" >&2
  echo "$output" >&2
  exit 1
fi
