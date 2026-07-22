#!/usr/bin/env bash
set -euo pipefail

# Usage: prefetch_modio.sh --game <id> --modId <id> [--fileId <id>] [--output-file <file>]
# Requires MODIO_API_KEY to be available to the build sandbox via /secrets.

fileId=""
outFile=""
while [[ $# -gt 0 ]]; do
  case $1 in
  --game)
    game="$2"
    shift 2
    ;;
  --modId)
    modId="$2"
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

if [[ -z ${game:-} || -z ${modId:-} ]]; then
  echo "Missing --game or --modId argument" >&2
  exit 1
fi

fileIdArg=""
[[ -n $fileId ]] && fileIdArg="fileId = ${fileId};"

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
}).fetchModIO {
  game = ${game};
  modId = ${modId};
  ${fileIdArg}
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
    echo "fetchModIO {"
    echo "  game = ${game};"
    echo "  modId = ${modId};"
    [[ -n $fileId ]] && echo "  fileId = ${fileId};"
    echo "  sha256 = \"${gotHash}\";"
    echo "}"
  } >>"$outFile"
  echo "Wrote suggestion to $outFile"
fi

echo "---"
echo "got: ${gotHash}"
