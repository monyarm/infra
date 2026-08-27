#!/usr/bin/env bash
set -euo pipefail

# Usage: prefetch_steam.sh --appId <id> --depotId <id> --manifestId <id>
#   --filelist <path> [--output-file <file>]

outFile=""
while [[ $# -gt 0 ]]; do
  case $1 in
  --appId | --depotId | --manifestId | --filelist | --output-file)
    key="${1#--}"
    printf -v "$key" '%s' "$2"
    shift 2
    ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

if [[ -z ${appId:-} || -z ${depotId:-} || -z ${manifestId:-} || -z ${filelist:-} ]]; then
  echo "Missing required Steam arguments" >&2
  exit 1
fi

filelistNix=$(sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/"/' "$filelist" | tr '\n' ' ')

build_expr() {
  local hashVal="$1"
  cat <<EOF
let
  pkgs = import <nixpkgs> {};
in
(import ./lib/fetchers.nix {
  inherit pkgs;
  dirs = null;
  importSopsString = null;
  urlEncode = x: x;
  splitFiles = (fileList: _drv: map (_: _drv) fileList);
  removeFiles = (paths: drv: drv);
  getFileNameFromUrl = _u: "download";
  sources = null;
}).fetchSteam {
  appId = ${appId};
  depotId = ${depotId};
  manifestId = ${manifestId};
  filelist = [ ${filelistNix} ];
  sha256 = "${hashVal}";
}
EOF
}

build_expr 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='

echo "Running initial build to discover fetched hash (this will fail)..."
set +e
initial_out=$(nix-build -E "$(build_expr 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=')" --no-out-link --builders "" 2>&1)
initial_rc=$?
set -e
if [[ $initial_rc -eq 0 ]]; then
  echo "Unexpected success on initial build; nothing to do." >&2
  exit 0
fi

gotHash=$(printf '%s' "$initial_out" | sed -n 's/.*got:[[:space:]]*\([^[:space:]]*\).*/\1/p' | tail -n1)
if [[ -z $gotHash ]]; then
  echo "Failed to extract got hash from nix output" >&2
  printf '%s\n' "$initial_out" >&2
  exit 1
fi

echo "Rebuilding with correct hash to verify..."
nix-build -E "$(build_expr "$gotHash")" --no-out-link --builders "" >/dev/null

if [[ -n $outFile ]]; then
  {
    echo "fetchSteam {"
    echo "  appId = ${appId};"
    echo "  depotId = ${depotId};"
    echo "  manifestId = ${manifestId};"
    echo "  filelist = [ ${filelistNix} ];"
    echo "  sha256 = \"${gotHash}\";"
    echo "}"
  } >>"$outFile"
fi

echo "got: ${gotHash}"
