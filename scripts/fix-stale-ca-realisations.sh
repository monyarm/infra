#!/usr/bin/env bash
# Fixes "error: some outputs are unexpectedly invalid" on remote builds of
# floating-CA derivations (wallpapers, romdirs, optimize stages, ...).
#
# Cause: the local DB keeps a realisation (drv^out -> path) after GC/delete
# removed the path. build-remote only copies back CA outputs that have *no*
# local realisation (build-remote.cc: `if (!store->queryRealisation(...))`),
# never checking the path is valid -- so the builder builds it, nothing comes
# back, and the build dies. Retries and --keep-going don't help.
#
# Fix: find every realisation in the installable's closure whose path is
# missing here, and copy those paths back from the builder. No DB edits.
# Paths the builder lacks too are listed at the end; building them once puts
# them on the builder, then rerun this.
#
# Usage: scripts/fix-stale-ca-realisations.sh [installable]
#   default installable: this host's NixOS toplevel
#   BUILDER env: store URI to copy from (default ssh-ng://monyarm@monyarm)
set -euo pipefail

installable=${1:-"${HOME}/.nix#nixosConfigurations.$(hostname).config.system.build.toplevel"}
builder=${BUILDER:-ssh-ng://monyarm@monyarm}
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT

echo "== eval ${installable}" >&2
top=$(nix path-info --impure --derivation "${installable}")

echo "== floating-CA outputs" >&2
nix derivation show -r "${top}" | jq -r '(.derivations // .) | to_entries[]
  | .key as $k | .value.outputs | to_entries[]
  | select(.value.method != null and .value.path == null and .value.hash == null)
  | "/nix/store/\($k)^\(.key)"' >"${work}/outputs"
wc -l <"${work}/outputs" >&2

# One lookup per output: a single unbuilt drv aborts a batched call.
echo "== realisations" >&2
# shellcheck disable=SC2016 # $1 is for the inner sh
xargs -a "${work}/outputs" -d '\n' -P 16 -I{} sh -c \
  'nix realisation info --json "$1" 2>/dev/null || true' _ {} |
  jq -r '.[] | .value.outPath? // empty' | sort -u |
  sed 's|^|/nix/store/|' >"${work}/paths"
wc -l <"${work}/paths" >&2

echo "== missing locally" >&2
xargs -a "${work}/paths" -d '\n' nix-store --check-validity --print-invalid >"${work}/stale" || true
cat "${work}/stale" >&2
[[ -s ${work}/stale ]] || exit 0

# Per path: one the builder lacks would abort a batched copy.
echo "== copy from ${builder}" >&2
missing=()
while read -r p; do
  nix copy --no-check-sigs --from "${builder}" "${p}" 2>/dev/null || missing+=("${p}")
done <"${work}/stale"

if ((${#missing[@]})); then
  echo "== not on builder either:" >&2
  printf '%s\n' "${missing[@]}" >&2
fi
