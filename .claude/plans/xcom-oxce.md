# X-COM UFO Defense OXCE Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native Linux X-COM: UFO Defense installation using OpenXcom Extended (OXCE), separately fetched original data, writable runtime state, and a verified mod path.

**Architecture:** Package OXCE separately because `pkgs.openxcom` is the legacy engine. Fetch only legally owned UFO data from Steam or GOG, expose it under OXCE's expected `UFO/` layout, and wrap the engine so saves and configuration never target the Nix store. Treat mods as versioned, separately verified content.

**Tech Stack:** Nix, CMake, SDL2, YAML, existing `fetchSteam`/`fetchGOG` helpers, Home Manager game modules, OXCE.

**Spec:** Research formerly recorded in `GAME_IDEAS.md`; source evidence is listed below.

## Global Constraints

- Use OpenXcom Extended, not legacy OpenXcom.
- Do not reuse `pkgs.openxcom` as an OXCE package.
- Do not redistribute proprietary UFO Defense data with the engine package.
- Pin exact Steam depot/manifest or authenticated GOG installer metadata.
- Keep `GEODATA`, `GEOGRAPH`, `MAPS`, `ROUTES`, `SOUND`, `TERRAIN`, `UFOGRAPH`, and `UNITS` under `UFO/`.
- Do not use XcomUtil-modified files as the vanilla base data.
- Keep saves, configuration, logs, and user mods outside `/nix/store`.
- Stage new `.nix` files before flake evaluation.
- Do not activate Home Manager or NixOS during verification.

## Evidence

- OXCE status: https://openxcom.org/2026/01/whats-the-deal-with-openxcom-extended/
- OXCE source: https://github.com/MeridianOXC/OpenXcom/tree/oxce-plus
- UFO data layout: https://raw.githubusercontent.com/OpenXcom/OpenXcom/master/bin/UFO/README.txt
- Steam app: https://store.steampowered.com/app/7760/XCOM_Enemy_Unknown/
- GOG product: https://www.gog.com/en/game/xcom_ufo_defense
- Mod ecosystem: https://openxcom.org/forum/index.php?board=22.0 and https://openxcom.mod.io/

## File Map

- Create: `packages/openxcom-extended.nix` for the OXCE engine.
- Create: `hosts/home/monyarm/games/OpenXcom/default.nix` for registration and launcher wiring.
- Create: `hosts/home/monyarm/games/OpenXcom/data.nix` for filtered UFO data.
- Create: `hosts/home/monyarm/games/OpenXcom/mods/` only after one compatible mod has a stable source.
- Modify: package import/overlay files if new package arguments require threading.

## Implementation Tasks

### Task 1: Pin and Package OXCE

**Files:**

- Create: `packages/openxcom-extended.nix`

- Modify: `sources.toml` and generated source metadata through the existing update workflow

- Test: package evaluation and build

- [ ] Confirm the maintained OXCE revision and source archive or Git revision.

- [ ] Package with current SDL/YAML dependencies and repository source-pinning conventions.

- [ ] Install the OXCE executable without bundling UFO Defense data.

- [ ] Build the package and verify the binary starts far enough to report its data-directory configuration.

### Task 2: Fetch and Filter Original UFO Data

**Files:**

- Create: `hosts/home/monyarm/games/OpenXcom/data.nix`

- Modify: source metadata only after successful prefetch

- Test: extraction and file-list checks

- [ ] Prefer owned Steam app `7760`; use `os = "windows"` because its release is DOSBox-wrapped Windows content.

- [ ] Record the exact depot ID, manifest ID, file list, and fixed-output hash.

- [ ] If using GOG, verify the extracted `XCOM`/`UFO` tree before selecting paths.

- [ ] Install only the original required data under `UFO/` and exclude DOSBox executables and launchers.

- [ ] Add build-time assertions naming every missing required directory.

### Task 3: Add Runtime Wrapper and Game Registration

**Files:**

- Create: `hosts/home/monyarm/games/OpenXcom/default.nix`

- Modify: existing Steam shortcut/game registry module

- Test: launcher invocation and writable-state behavior

- [ ] Pass immutable data through OXCE's data option or configuration file.

- [ ] Set user/config/save paths beneath writable XDG locations.

- [ ] Register one vanilla UFO Defense shortcut only after direct wrapper startup works.

- [ ] Test first launch, new campaign, tactical battle, save/load, and restart persistence.

### Task 4: Verify One OXCE Mod

**Files:**

- Create: one explicitly named file under `hosts/home/monyarm/games/OpenXcom/mods/`

- Modify: `hosts/home/monyarm/games/OpenXcom/default.nix`

- Test: mod startup

- [ ] Select one OXCE-compatible mod from the official forum, mod.io, or ModDB.

- [ ] Record its required OXCE version, master data, provenance, archive hash, and directory layout.

- [ ] Install it as a separate immutable mod directory and keep it optional.

- [ ] Test vanilla and modded launchers independently.

- [ ] Do not add a general forum scraper until stable versioned downloads are demonstrated.

## Verification

- Check for another Nix process with `pgrep -x nix` before evaluation or build.
- Build OXCE and the filtered data derivation.
- Inspect the output for the required `UFO/` tree and absence of DOSBox launchers.
- Run a vanilla campaign, tactical mission, save/load cycle, and restart.
- Run the mod if Task 4 is implemented.
- Run `nix fmt` and `nix flake check`.
