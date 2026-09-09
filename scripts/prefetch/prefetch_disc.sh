#!/usr/bin/env bash
set -euo pipefail

# Usage: prefetch_disc.sh --mode image|contents|redumper --name "<redump title>"
#   [--system <redump-code>] [--device /dev/sr0] [--speed 8] [--retries 100]
#   [--output-file <file>]
#
# Unlike this repo's credential-based prefetch scripts (prefetch_steam.sh,
# prefetch_gdrive.sh, which force --builders "" since their creds are local
# to wherever they're invoked), disc ripping's "credential" is physical
# drive access, which lives on monyarm specifically -- so this one is meant
# to run from anywhere and let Nix's own requiredSystemFeatures-based
# distributed-build dispatch route it to monyarm, same as any other build.
# Needs the invoking machine's nix.conf to actually know monyarm advertises
# cdrom/redumper-drive (buildMachines list, hosts/modules/base/default.nix).
#
# --mode contents (PC games, lib/fetchers/disc.nix's ripDiscContents): sha256
#   isn't known ahead of time -- runs the classic fake-hash-then-real-hash
#   discovery dance (same pattern as prefetch_steam.sh/prefetch_gdrive.sh).
# --mode image / --mode redumper: the expected hash already comes from the
#   redump DAT (ripDisc/ripDiscRedumper look it up themselves) -- nothing to
#   discover, this just runs the real rip and reports pass/fail. redumper's
#   multi-track case (ripDiscRedumper returns { cue; bins; } rather than one
#   derivation) is detected and each piece built individually.

mode="" name="" system="" device="/dev/sr0" speed=8 retries=100 outFile=""
while [[ $# -gt 0 ]]; do
  case $1 in
  --output-file)
    outFile="$2"
    shift 2
    ;;
  --mode | --name | --system | --device | --speed | --retries)
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

case "$mode" in
image | contents | redumper) ;;
*)
  echo "--mode must be image, contents, or redumper" >&2
  exit 1
  ;;
esac
[[ -n $name ]] || {
  echo "--name required" >&2
  exit 1
}
if [[ $mode != contents && -z $system ]]; then
  echo "--system required for --mode $mode (redump code, e.g. psx/ps2/gc)" >&2
  exit 1
fi

fetchers_expr() {
  cat <<EOF
(import ./lib/fetchers.nix {
  # disc-rip-helper isn't a real nixpkgs package -- it comes from this
  # repo's own packages/ overlay (see hosts/default.nix's own overlays
  # list), which a bare 'import <nixpkgs> {}' doesn't apply.
  pkgs = import <nixpkgs> {
    overlays = [
      (final: prev: import ./packages {
        pkgs = final;
        inherit (prev) lib;
        sources = import ./sources.nix;
      })
    ];
  };
  dirs = null;
  importSopsString = null;
  urlEncode = x: x;
  splitFiles = (fileList: _drv: map (_: _drv) fileList);
  removeFiles = (paths: drv: drv);
  getFileNameFromUrl = _u: "download";
  sources = import ./sources.nix;
})
EOF
}

case "$mode" in
contents)
  build_expr() {
    local hashVal="$1"
    cat <<EOF
$(fetchers_expr).ripDiscContents {
  name = "${name}";
  device = "${device}";
  sha256 = "${hashVal}";
}
EOF
  }

  echo "Running initial build to discover the extracted tree's hash (this will fail)..."
  echo "(streaming live below -- disc-rip-helper's announce/wait-for-disc messages show up here)"
  set +e
  # nix-build streams the build log live by default, but 2>&1 into a
  # $(...) capture (needed for hash-extraction below) buffers everything
  # silently until the build finishes -- tee to stderr to get it back.
  # pipefail (set at the top of this script) keeps $? as nix-build's real
  # exit code, not tee's.
  initial_out=$(nix-build -E "$(build_expr 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=')" --no-out-link 2>&1 | tee /dev/stderr)
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

  echo "Rebuilding with the discovered hash to verify..."
  nix-build -E "$(build_expr "$gotHash")" --no-out-link >/dev/null

  if [[ -n $outFile ]]; then
    {
      echo "ripDiscContents {"
      echo "  name = \"${name}\";"
      echo "  sha256 = \"${gotHash}\";"
      echo "}"
    } >>"$outFile"
    echo "Wrote suggestion to $outFile"
  fi
  echo "---"
  echo "got: ${gotHash}"
  ;;

image)
  expr="$(fetchers_expr).ripDisc { name = \"${name}\"; system = \"${system}\"; device = \"${device}\"; }"
  echo "Running rip (hash comes from the redump DAT, not discovered here)..."
  nix-build -E "$expr" --no-out-link
  echo "Done -- hash matched the redump DAT entry."
  ;;

redumper)
  expr="$(fetchers_expr).ripDiscRedumper { name = \"${name}\"; system = \"${system}\"; device = \"${device}\"; speed = ${speed}; retries = ${retries}; }"

  isMultiTrack=$(nix eval --impure --expr "(${expr}) ? bins" 2>/dev/null)
  if [[ $isMultiTrack == "true" ]]; then
    echo "Multi-track disc -- building cue + each track individually."
    hasCue=$(nix eval --impure --expr "(${expr}) ? cue && (${expr}).cue != null")
    if [[ $hasCue == "true" ]]; then
      echo "Building cue sheet..."
      nix-build -E "(${expr}).cue" --no-out-link
    fi
    binCount=$(nix eval --impure --expr "builtins.length (${expr}).bins")
    for ((i = 0; i < binCount; i++)); do
      echo "Building track $((i + 1))/${binCount}..."
      nix-build -E "builtins.elemAt (${expr}).bins ${i}" --no-out-link
    done
    echo "Done -- all tracks matched the redump DAT entry."
  else
    echo "Running rip (hash comes from the redump DAT, not discovered here)..."
    nix-build -E "$expr" --no-out-link
    echo "Done -- hash matched the redump DAT entry."
  fi
  ;;
esac
