---
name: reference-engine-candidate-status-2026-11-17
description: "Verified 2026-11-17 statuses for the candidate engines discussed after the RecompLauncher survey: openQ4 is singleplayer with two campaigns, NeoTS2 is The Sims 2, NeoRTCW vs iortcw/RealRTCW layering, Commander Genius covers Keen 1-6 + Dreams + Cosmo, Dusklight version and Wii support"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-17T00:22:48.584Z
---

Verified 2026-11-17, for the candidate-engine set that followed the RecompLauncher survey:

**openQ4** (`themuffinator/openQ4`) — **not multiplayer-only**; `docs/user/campaigns.md` says it plays two story campaigns: the original Quake 4 campaign and *The Awakening* (recovered expansion), each with its own saves on its own game code. v0.14.1 beta (Nov 2026 — 0.14.0 was withdrawn as broken), Linux supported, absent from nixpkgs. Quake 4 [Steam 2210] is a genuine singleplayer candidate.

**NeoTS2** (`Asli-s/NeoTS2`) — **The Sims 2**, confirmed from its README 2026-11-17 (the assistant had wrongly called it something else and was corrected): "A new, open-source, 64-bit engine for The Sims 2" that loads game data from an existing installation. Saving is not supported yet. The user owns only The Sims 4 [1222670], so there is no data source — no plan.

**NeoRTCW vs iortcw/RealRTCW** — different layers of one lineage: iortcw is the original RTCW 1.51 engine port (1.51c, 2019, dormant) and is what the repo builds via RealRTCW; RealRTCW is a content overhaul (weapons, balance, UI) on that engine. `klaussilveira/neortcw` 1.0.0 is a fork *of iortcw* + ioq3 adding a unified CMake build (SP+MP+ET), automatic Steam data detection on all platforms, higher tick rate with client snaps sync and prediction improvements — vanilla RTCW modernised, no content. Package it only if plain RTCW SP is wanted next to RealRTCW.

**Commander Genius** — main repo is GitLab (`Dringgstein/Commander-Genius`); the GitHub `gerstrong/Commander-Genius` is a mirror (3.6.4). Interpreter for **Commander Keen 1–6, Keen Dreams, and Cosmo's Cosmic Adventure** ("Keen 1-6 and Dreams are fully supported"). Absent from nixpkgs; needs SDL2 + a data dir. Covers Commander Keen Complete Pack [9180] + Keen Dreams [356200], so the earlier "Keen 1–6 have no port" claim is **wrong**; it overlaps but is broader than ReflectionHLE (which covers Keen Dreams + Bio Menace). Build trap: its CMake `FetchContent`s SDL2/SDL2_image/SDL2_mixer/SDL2_ttf/curl for static builds, so the package must supply system libraries or it hits the network. CMake minimum is 3.29.

**Dusklight** — nightlies/upstream 2.0.3 vs pinned nixpkgs 2.0.2 (so a `sources.dusklight.toml` override). Supports all commercial discs except Wii's Korean release, but the underlying `zeldaret/tp` decomp is only matching for GameCube, so a Wii disc runs with the GameCube HUD.

**Flame** (`DiaLight/Flame`) — Dungeon Keeper 2, but Windows-only in practice: its README says it "modifies the Dungeon Keeper 2 code" and works against the disk/Steam/GOG payload, i.e. patches the Windows game rather than reimplementing it.

**Why:** these statuses flipped or refined earlier assumptions in the plan set; each cost a docs/release read to establish.
**How to apply:** cite these instead of re-deriving; do not repeat the "Keen 1–6 unported", "Quake 4 is MP-only" or the NeoTS2 mix-up claims.
