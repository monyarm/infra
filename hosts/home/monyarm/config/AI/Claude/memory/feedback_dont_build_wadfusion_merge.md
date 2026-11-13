---
name: feedback-dont-build-wadfusion-merge
description: "Don't build the WadFusion custom_maps merge pk3 to verify map-pool additions; it triggers slow optimization of everything."
metadata:
  node_type: memory
  type: feedback
  originSessionId: ecdaf127-7eab-4e29-9978-aea0500e6b10
  modified: 2026-11-10T12:01:30.586Z
---

Do not build `custom_maps.pk3`/`custom_maps.pk7` (Doom/wad/wadfusion.nix `customMaps`, fed by build_custom_maps.py) just to verify adding a source to the map pool.

**Why:** building the merge pulls every map-pool source through the optimize pipeline, which takes forever. User stopped it explicitly (2026-11-10).

**How to apply:** when adding a source to `customMapsManifest.sources`, build only the new source wad itself (e.g. `config.games.doom.wads.<x>`), and leave the merge build to the user. Related: [[feedback-no-tail-short-logs]].
