---
name: project_next_engine_prioritization
description: "2026-11-17 prioritisation on which engine/reimplementation to package next: mkxp-z, KeeperFX, then cheap nixpkgs wins; broader survey with next two picks R.E.L.I.V.E. and OpenMW, plus the rejected candidates and why, and the late-2026-11-17 freeware sweep adding OpenOMF/OpenRA as new candidates"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-17T00:33:45.734Z
---

Engine/reimplementation prioritisation answered 2026-11-17 (follow-up to the 2026-11-16 runtime-categories survey and the `.claude/plans` files `next-games-report.md`, `renpy-catalog-and-games.md`, `daggerfall-unity-but-check-polished-star.md`, `wadfusion-doom-roguelike-stack.md`).

Pinned-nixpkgs presence actually verified (attribute lookups):
- **present**: `easyrpg-player`, `openrct2`, `opentyrian`, `gemrb`, `wargus`, `srb2`, `ringracers`, `freedink`
- **absent (needs a real derivation)**: `mkxp-z`, `keeperfx`, `ags`, `war1gus`, `openjkdf2`, `mkxp`

Headline sequence: **mkxp-z first, KeeperFX second**, then the nixpkgs-ready config-plus-data jobs (OpenRCT2 via `fetchGOG rollercoaster_tycoon_deluxe` + `rct2Path`, OpenTyrian, Wargus, GemRB, freedink, srb2, ringracers). OpenJKDF2 is the third worthwhile real build (pairs with the existing TFE Dark Forces module); skip KaM Remake, Sonic Mania decomp, and GemRB-for-BG-EE (BG EE ships its own Linux build).

- **mkxp-z** — RGSS runner (RPG Maker XP/VX/VX Ace), unlocks 12–14 owned titles, one CMake build then a thin per-title wrapper shaped like `RenPy/mkGame.nix`. Won on category size: RPG Maker is the one big surveyed category where the repo has editor config and nothing else, and all titles share `Data/*.rvdata2` (+ optional `.rgss3a`) layout.
- Caveat recorded: **Treasure of Nadia is RPG Maker MV** (JS/NW.js/Electron-family), so it is outside mkxp-z's scope.
- **KeeperFX** — real Linux build, point its `DK` data dir at the GOG Dungeon Keeper Gold install.

Deliberately skipped: Ruffle/Flash (13 titles but the AIR ones can't boot; only Samorost 1 is clean), GameMaker (19 titles, no FOSS runner), XNA/FNA (17 titles, per-title ports, good ones already native), Java (JRE wrapper, Mindustry already in nixpkgs), and generic DOSBox — `buildDosBox` stays for the long tail (SSI Gold Box packs, Keen, Time Commando) because FOSS engines beat a bare DOSBox profile for the marquee DOS titles.

Broader follow-up sweep of `games-list.new` on 2026-11-17 found these additional owned titles with a viable engine and no plan yet:
- **nixpkgs already, data-plumbing only**: Yamagi Quake II (`pkgs.yamagi-quake2`, Quake II [2320] + RTX copy, `baseq2/*.pak`), OpenJK (Jedi Academy [6020], SP+MP), OpenMW (Morrowind [22320] — mod story, not just PATH), Arx Libertatis (Arx Fatalis [1700], fixes retail widescreen/input).
- **own small derivation**: R.E.L.I.V.E. (Oddworld: Abe's Oddysee [15700] + Exoddus [15710], both Windows builds in the GOG release — one derivation, two wrappers, same shape as the ReflectionHLE plan), Fallout 1 CE / Fallout 2 CE ([38400/38410], decompiled, clean CMake, no nixpkgs), Sonic Mania decompilation ([584400], needs `Data.rsdk` from Steam).
- **not worth it**: GemRB (only helps the originals; the EEs ship native Linux builds), reone (KotOR can't be completed), OpenJO (abandoned), re3/reVC (DMCA'd, OpenRW unfinished), KaM Remake (Delphi/Lazarus build), Prey2006 and HPL2 (half-alive upstream).
- Not owned, so out of scope: CorsixTH, DXX-Rebirth, NBlood, Shockolate, OpenRA, VCMI/fheroes2, OpenDune, openblack, OpenGothic, Stracciatella, OpenApoc.

If two more are added to the queue, the picks are **R.E.L.I.V.E.** (two titles from one build, mirrors the ReflectionHLE plan) and **OpenMW** (biggest owned title left; mod handling is the real design problem).

Later on 2026-11-17 a second sweep asked for "games that went free + have an engine" (details in `reference_freeware_games_with_engines.md`); it surfaced **OpenOMF (One Must Fall: 2097)** as the best new candidate — free registered data since 1999-02-10, native Linux, absent from nixpkgs — with **OpenRA** (C&C/Red Alert freeware) as the larger but data-plumbing-only option since `openra` is already in nixpkgs. Plans for either were offered; the user had not chosen as of that point.
