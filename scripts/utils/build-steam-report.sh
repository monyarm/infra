#!/usr/bin/env bash
set -euo pipefail

# Builds just the Steam artwork report (games.json + artwork-report.html),
# skipping the rest of the home-manager config's actual build output.
# Run from the repo root (~/.nix).

json_path=$(nix build --impure --no-link --print-out-paths \
  '.#homeConfigurations.monyarm.config.home.file.".steam/games/games.json".source')

html_path=$(nix build --impure --no-link --print-out-paths \
  '.#homeConfigurations.monyarm.config.home.file.".steam/games/artwork-report.html".source')

echo "games.json:           $json_path"
echo "artwork-report.html:  $html_path"
