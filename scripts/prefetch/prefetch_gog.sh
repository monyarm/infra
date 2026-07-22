#!/usr/bin/env bash
set -euo pipefail

# Usage: prefetch_gog.sh --game <gamename> --fileId <id> [--output-file <file>]
# Requires GOG_REFRESH_TOKEN to be available to the build sandbox via /secrets.
# Obtain it once by visiting (in a real browser, logged into GOG):
#   https://auth.gog.com/auth?client_id=46899977096215655&redirect_uri=https%3A%2F%2Fembed.gog.com%2Fon_login_success%3Forigin%3Dclient&response_type=code
# then exchanging the resulting ?code= for a refresh_token via:
#   curl "https://auth.gog.com/token?client_id=46899977096215655&client_secret=9d85c43b1482497dbbce61f6e4aa173a433796eeae2ca8c5f6129f2dc4de46d9&grant_type=authorization_code&code=<CODE>&redirect_uri=https%3A%2F%2Fembed.gog.com%2Fon_login_success%3Forigin%3Dclient"

outFile=""
while [[ $# -gt 0 ]]; do
  case $1 in
  --game)
    game="$2"
    shift 2
    ;;
  --fileId)
    fileId="$2"
    shift 2
    ;;
  --output-file)
    outFile="$2"
    shift 2
    ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

if [[ -z ${game:-} || -z ${fileId:-} ]]; then
  echo "Missing --game or --fileId argument" >&2
  exit 1
fi

build_expr() {
  local hashVal="$1"
  cat <<EOF
(import ./lib/fetchers.nix {
  pkgs = import <nixpkgs> {};
  dirs = null;
  importSopsString = null;
  urlEncode = x: x;
  splitFiles = (fileList: _drv: map (_: _drv) fileList);
  getFileNameFromUrl = _u: "download";
  sources = null;
}).fetchGOG {
  game = "${game}";
  fileId = ${fileId};
  sha256 = "${hashVal}";
}
EOF
}

echo "Running initial build to discover fetched hash (this will fail)..."
set +e
initial_out=$(nix-build -E "$(build_expr 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=')" --no-out-link --builders "" 2>&1)
initial_rc=$?
set -e
if [[ $initial_rc -eq 0 ]]; then
  echo "Unexpected success on initial build; nothing to do." >&2
  echo "$initial_out"
  exit 0
fi

gotHash=$(printf '%s' "$initial_out" | sed -n 's/.*got:[[:space:]]*\([^[:space:]]*\).*/\1/p' | tail -n1)
if [[ -z $gotHash ]]; then
  echo "Failed to extract got hash from nix output" >&2
  echo "$initial_out" >&2
  exit 1
fi

echo "Rebuilding with correct hash to verify..."
if ! nix-build -E "$(build_expr "$gotHash")" --no-out-link --builders "" >/dev/null 2>&1; then
  echo "Rebuild with the discovered hash failed" >&2
  exit 1
fi

if [[ -n $outFile ]]; then
  {
    echo "fetchGOG {"
    echo "  game = \"${game}\";"
    echo "  fileId = ${fileId};"
    echo "  sha256 = \"${gotHash}\";"
    echo "}"
  } >>"$outFile"
  echo "Wrote suggestion to $outFile"
fi

echo "---"
echo "got: ${gotHash}"
