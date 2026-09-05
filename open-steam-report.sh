#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
report_file="/tmp/steam-artwork-report.html"
apply_file="${TMPDIR:-/tmp}/steamgriddb-apply.json"
port=8743

rm -f "${report_file}"

# nix build (not eval) so the report's CDN-fetched (content-addressed)
# images actually get built -- eval-ing config.home.file…text just
# stringifies unresolved CA placeholders instead of real store paths.
built=$(nix build --impure --no-link --print-out-paths \
  "${repo_root}#homeConfigurations.\"monyarm\".config.home.file.\".steam/games/artwork-report.html\".source")
cp -f "${built}" "${report_file}"
echo "Report: ${report_file}"

REPO_ROOT="${repo_root}" "${repo_root}/steamgriddb-proxy.py" &
proxy_pid=$!
trap 'kill "${proxy_pid}" 2>/dev/null || true' EXIT

for _ in $(seq 1 30); do
  curl -sf "http://127.0.0.1:${port}/health" >/dev/null 2>&1 && break
  sleep 0.1
done

echo "SteamGridDB proxy: http://127.0.0.1:${port} (open the report and pick images; waiting for Submit)"
wait "${proxy_pid}"
trap - EXIT

echo "Apply JSON: ${apply_file}"
