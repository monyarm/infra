# Tomb Raider I-III TRX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Tomb Raider I, II, and III through the actively maintained TRX engine, with separately fetched original data and custom-level support.

**Architecture:** Use the combined TRX distribution, currently released as TRX 1.10.2, rather than treating TR1X, TR2X, and TR3X as separate engines. Package the open-source Linux engine separately from proprietary Steam/GOG data, assemble TRX's `games/tr1`, `games/tr2`, and `games/tr3` directories, and expose independent campaign launchers with writable state.

**Tech Stack:** Nix, upstream Linux release or source build, SDL2, GLEW, PulseAudio, FFmpeg, existing `fetchSteam`/`fetchGOG` helpers, Home Manager game modules.

**Spec:** Research formerly recorded in `GAME_IDEAS.md`; source evidence is listed below.

## Global Constraints

- Use current TRX, not OpenLara, for the complete TR1-TR3 target.
- Pin a release tag, preferably `trx-1.10.2`.
- Keep proprietary level, FMV, music, and audio data separate from the engine.
- Steam app IDs are `224960` for TR1, `225300` for TR2, and `225320` for TR3.
- Record exact depot, manifest, file-list, and fixed-output hash metadata.
- Keep saves, settings, cache, screenshots, and generated state outside `/nix/store`.
- Do not add a generic mod fetcher before one concrete custom level proves the required layout.
- Tomb Raider: Anniversary is outside this target.
- Do not activate Home Manager or NixOS during verification.

## Evidence

- TRX source: https://github.com/LostArtefacts/TRX
- Current release: https://github.com/LostArtefacts/TRX/releases/tag/trx-1.10.2
- Installation layout: https://raw.githubusercontent.com/LostArtefacts/TRX/develop/docs/trx/INSTALLING.md
- Custom levels: https://raw.githubusercontent.com/LostArtefacts/TRX/develop/docs/trx/LEVELS.md
- Command line: https://raw.githubusercontent.com/LostArtefacts/TRX/develop/docs/trx/COMMAND_LINE.md
- OpenLara comparison: https://github.com/XProger/OpenLara

## File Map

- Create: `packages/trx.nix` for the pinned TRX engine.
- Create: `hosts/home/monyarm/games/TRX/default.nix` for registration and launchers.
- Create: `hosts/home/monyarm/games/TRX/data.nix` for filtered original data.
- Create: `hosts/home/monyarm/games/TRX/levels/` only after one custom level is verified.
- Modify: package import/overlay files if package arguments require threading through both overlay sites.

## Implementation Tasks

### Task 1: Pin and Package TRX

**Files:**

- Create: `packages/trx.nix`

- Modify: `sources.toml` and generated source metadata through the existing update workflow

- Test: package evaluation and build

- [ ] Pin the `trx-1.10.2` release and inspect whether the Linux artifact is self-contained.

- [ ] Prefer the release artifact if dependencies can be expressed cleanly; otherwise build from source with documented Linux dependencies.

- [ ] Install the executable and open-source `data/*/ship` assets without proprietary game files.

- [ ] Thread package arguments through every required package import site.

- [ ] Build the package and verify it reads its bundled engine assets.

### Task 2: Fetch and Filter the Three Games

**Files:**

- Create: `hosts/home/monyarm/games/TRX/data.nix`

- Modify: source metadata only after successful prefetch

- Test: extraction and layout checks

- [ ] Prefetch Steam depots for app IDs `224960`, `225300`, and `225320`, recording exact depot IDs, manifests, file lists, and hashes.

- [ ] Use GOG only after verifying real product slugs and installer file IDs.

- [ ] Retain TR1 `data/*.phd`, FMV, and music files.

- [ ] Retain TR2 `data/*.tr2`, `main.sfx`, FMV, and MP3 music files.

- [ ] Retain TR3 `data/*.tr2`, `main.sfx`, `audio/cdaudio.wad`, cutscene `.tr2` files, and FMV files.

- [ ] Add build-time assertions for required files and reject empty or mis-rooted extractions.

### Task 3: Assemble TRX Runtime Layout

**Files:**

- Create: `hosts/home/monyarm/games/TRX/default.nix`

- Test: assembled directory and launcher fixtures

- [ ] Assemble the immutable runtime tree:

```text
games/tr1/{levels,fmv,music}
games/tr2/{levels,fmv,music}
games/tr3/{levels,fmv,audio,cuts}
```

- [ ] Include matching upstream `data/tr1/ship`, `data/tr2/ship`, and `data/tr3/ship` assets.
- [ ] Set `TRX_GAMES_DIR` and documented config/save/cache variables through the wrapper.
- [ ] Keep each campaign's mutable state in a distinct writable directory.
- [ ] Verify the wrapper does not write into package or fetched-data outputs.

### Task 4: Register Independent Campaign Launchers

**Files:**

- Modify: `hosts/home/monyarm/games/TRX/default.nix`

- Modify: existing Steam shortcut registration if appropriate

- Test: each campaign launcher

- [ ] Add separate TR1, TR2, and TR3 commands using TRX's documented game-selection configuration.

- [ ] Add shortcuts only after direct launchers work; shortcuts must target wrappers, not proprietary binaries.

- [ ] Test each campaign reaches its menu, loads a level, accepts input and audio, and saves/loads progress.

### Task 5: Add One Verified Custom Level

**Files:**

- Create: one explicit file under `hosts/home/monyarm/games/TRX/levels/`

- Modify: `hosts/home/monyarm/games/TRX/default.nix`

- Test: custom-level launcher

- [ ] Select one custom level with stable source, provenance, and documented TR1, TR2, or TR3 compatibility.

- [ ] Inspect its level file, gameflow template, textures, audio, and auxiliary files.

- [ ] Preserve every required file under a dedicated immutable level directory.

- [ ] Launch it with TRX's documented `--level <path>` interface and required gameflow/config arguments.

- [ ] Keep the custom level optional and separate from base-game launchers.

- [ ] Defer generic level-host fetching until a second level demonstrates a reusable layout.

## Verification

- Check for another Nix process with `pgrep -x nix` before evaluation or build.
- Build the TRX package and all three filtered data outputs.
- Inspect the assembled tree against upstream `INSTALLING.md`.
- Run TR1, TR2, and TR3 through independent wrappers and test one save/load cycle each.
- Run the custom-level launcher if Task 5 is implemented.
- Confirm writable state never appears under `/nix/store`.
- Run `nix fmt` and `nix flake check`.
