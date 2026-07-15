#!/usr/bin/env bash
set -euo pipefail

# Usage: prefetchSteamCards --appId <appid> [--cardNames "card1,card2,..."] [--output-file <file>]

cardNamesArg=""
outFile=""
while [[ $# -gt 0 ]]; do
  case $1 in
  --appId)
    appId="$2"
    shift 2
    ;;
  --cardNames)
    cardNamesArg="$2"
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

if [[ -z ${appId:-} ]]; then
  echo "Missing --appId argument" >&2
  exit 1
fi

# Construct optional cardNames Nix fragment from provided arg
cardNamesNix=""
if [[ -n $cardNamesArg ]]; then
  read -r -a arr <<<"$(echo "$cardNamesArg" | tr ',' ' ')"
  cardNamesNix="cardNames = ["
  for n in "${arr[@]}"; do
    cardNamesNix+=" \"${n}\""
  done
  cardNamesNix+=" ];"
fi

build_expr() {
  local hashVal="$1"
  cat <<EOF
(import ./lib/fetchers.nix { pkgs = import <nixpkgs> {}; dirs = null; importSopsString = null; urlEncode = x: x; splitFiles = (fileList: _drv: _drv); }).fetchSteamCards {
  appId = ${appId};
  ${cardNamesNix}
  sha256 = "${hashVal}";
}
EOF
}

# First build intentionally with placeholder hash to get the 'got:' value
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

# Determine final card names: if provided, use them; otherwise rebuild with correct hash and list files
cardNamesFinal=""
if [[ -n $cardNamesArg ]]; then
  cardNamesFinal=$(echo "$cardNamesArg" | tr ',' ' ')
else
  echo "Rebuilding with correct hash to obtain output path..."
  outPath=$(nix-build -E "$(build_expr "$gotHash")" --no-out-link --builders "" 2>/dev/null)
  if [[ -z $outPath ]]; then
    echo "Failed to build with correct hash" >&2
    exit 1
  fi
  echo "Output path: $outPath"
  # List files in the output and collect .jpg names
  while IFS= read -r -d $'\0' f; do
    base=$(basename "$f")
    if [[ $base == *.jpg ]]; then
      cardNamesFinal+=" ${base%.jpg}"
    fi
  done < <(find "$outPath" -maxdepth 1 -type f -print0)
fi

# Write suggestion if requested
if [[ -n $outFile ]]; then
  echo "fetchSteamCards {" >>"$outFile"
  echo "  appId = ${appId};" >>"$outFile"
  if [[ -n $cardNamesFinal ]]; then
    echo -n "  cardNames = [" >>"$outFile"
    for n in $cardNamesFinal; do
      echo -n " \"${n}\"" >>"$outFile"
    done
    echo " ];" >>"$outFile"
  fi
  echo "  sha256 = \"${gotHash}\";" >>"$outFile"
  echo "}" >>"$outFile"
  echo "Wrote suggestion to $outFile"
fi

echo "---"
echo "got: ${gotHash}"
