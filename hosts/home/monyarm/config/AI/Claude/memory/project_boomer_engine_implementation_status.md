---
name: project-boomer-engine-implementation-status
description: "State of the 2026-11-14 implementation of the boomer-shooter plan: files written/staged, verified Steam depot facts, and the remaining hash-fill + flake check/build steps"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-14T00:19:20.632Z
---

Implementation of the 5-item order in `/home/monyarm/.opencode/plan/boomer-shooter-engine-options.md` started 2026-11-14 ("implement the plan file's stuff"). Files written and staged:

- `hosts/home/monyarm/games/EnemyTerritory.nix` — nixpkgs `etlegacy` + its `etlegacy-assets` pak fetch, no fetchSteam.
- `packages/realrtcw.nix` + `hosts/home/monyarm/games/RTCW.nix` — own RealRTCW derivation (make/GNUmakefile build, SDL3 + external ffmpeg; RealRTCW 5.3 is the last version not requiring FFmpeg 8), data from Steam depot 9011 of app 9010 (`main/*.pk3`).
- `hosts/home/monyarm/games/Doom3.nix` — RBDOOM-3-BFG, content = BFG depots 208202 (bulk ~7.3 GB) + 208203 (only `base/strings/english.lang` and `base/_sound_pc_en.resources`, no overlap with 208202 → hardlink-join into one basepath).
- `hosts/home/monyarm/games/HalfLife/{default,libs,half-life,opposing-force,blue-shift}.nix` — Xash3D-FWGS folder module (`mkHalfLife` factory, allowed as the multi-entry exception); `libs.nix` uses `pkgs.fetchgit` with `fetchSubmodules` because `fetchGitTree` skips submodules; hlsdk-portable branches: `valve`/`opfor`/`bshift`. Steam app 70: depot 1 = shared `valve/` content (4320 files), depots 51/71/130 = the per-game subsets.
- `sources.hl.toml` (hl.xash3d `[git]` from `xash3d-fwgs/continuous` + hlsdk branches) and `sources.rtcw.toml` (RealRTCW `[git-tag]`), regenerated via `update-sources.py`.
- `measure-compression.py` gained `xash3d` and `trx` categories/switches.

Remaining when the session paused: hashes still being discovered in the background (4 `fetchgit` submodule trees; 6 Steam depots via a `fetch-hash.sh` helper wrapping prefetch_steam.sh), then fill them in and run `nix flake check --impure` plus a toplevel build with `--max-jobs 1`. Nothing had been built or evaluated successfully yet.

**Why:** implementation spans many files and multi-hour hash discovery; a future session needs to know what already exists versus what the plan still describes as future work.
**How to apply:** treat the listed paths as existing work in progress rather than re-deriving the plan; do not re-survey the games list. Verified facts above (depot split, non-overlap, fetchGitTree-vs-submodules) are already encoded in the files' comments.
