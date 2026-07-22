#!/usr/bin/env bash
set -euo pipefail

# Usage: prefetch_thunderstore.sh --namespace <ns> --name <name> --version <version> [--output-file <file>]

outFile=""
while [[ $# -gt 0 ]]; do
  case $1 in
  --namespace)
    namespace="$2"
    shift 2
    ;;
  --name)
    pkgName="$2"
    shift 2
    ;;
  --version)
    version="$2"
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

if [[ -z ${namespace:-} || -z ${pkgName:-} || -z ${version:-} ]]; then
  echo "Missing --namespace, --name, or --version argument" >&2
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
}).fetchThunderstore {
  namespace = "${namespace}";
  name = "${pkgName}";
  version = "${version}";
  hash = "${hashVal}";
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
    echo "fetchThunderstore {"
    echo "  namespace = \"${namespace}\";"
    echo "  name = \"${pkgName}\";"
    echo "  version = \"${version}\";"
    echo "  hash = \"${gotHash}\";"
    echo "}"
  } >>"$outFile"
  echo "Wrote suggestion to $outFile"
fi

echo "---"
echo "got: ${gotHash}"
