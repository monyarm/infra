# STAR WARS Dark Forces The Force Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add STAR WARS: Dark Forces through the nixpkgs The Force Engine package and separately fetched, legally owned game data.

**Architecture:** Reuse `pkgs.theforceengine`, currently packaged at upstream 1.22.420, rather than creating a duplicate engine derivation. Fetch and filter the original data, principally `DARK.GOB`, then wrap TFE with writable user-data paths for saves, settings, and mods.

**Tech Stack:** Nix, existing `fetchSteam`/`fetchGOG` helpers, Home Manager game modules, `pkgs.theforceengine`, SDL/OpenGL runtime.

**Spec:** Research formerly recorded in `GAME_IDEAS.md`; source evidence is listed below.

## Global Constraints

- Reuse `pkgs.theforceengine`; do not package a second TFE engine.
- Keep GPL engine code separate from proprietary Dark Forces data.
- Steam app ID is `32400`; existing ownership/access is required because the listing is delisted.
- Use exact depot, manifest, file-list, and hash metadata for Steam extraction.
- Verify GOG availability and installer metadata before using `fetchGOG`.
- Keep `DARK.GOB` and associated original files immutable and all user state outside `/nix/store`.
- Treat Remaster HD assets as a separate optional source.
- Do not activate Home Manager or NixOS during verification.

## Evidence

- TFE source: https://github.com/TheForceEngine/TheForceEngine
- Current release: https://github.com/TheForceEngine/TheForceEngine/releases/tag/v1.22.420
- nixpkgs package: https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/th/theforceengine/package.nix
- Documentation: https://theforceengine.github.io/Documentation.html
- Steam app: https://store.steampowered.com/app/32400/STAR_WARS_Dark_Forces/
- Mod hub: https://df-21.net/

## File Map

- Create: `hosts/home/monyarm/games/DarkForces/default.nix` for registration and launch wiring.
- Create: `hosts/home/monyarm/games/DarkForces/data.nix` for filtered Steam or GOG data.
- Create: `hosts/home/monyarm/games/DarkForces/mods/` only for a later verified mod.
- Do not create an engine package unless the pinned nixpkgs package is unavailable or incompatible.

## Implementation Tasks

### Task 1: Confirm the Existing Engine Package

**Files:**

- Create: `hosts/home/monyarm/games/DarkForces/default.nix`

- Test: `pkgs.theforceengine` evaluation and executable discovery

- [ ] Confirm the package exposes the `theforceengine` executable.

- [ ] Confirm `TFE_DATA_HOME` or the supported equivalent redirects user data.

- [ ] Keep the engine package unmodified unless a concrete incompatibility is found.

### Task 2: Fetch and Filter Dark Forces Data

**Files:**

- Create: `hosts/home/monyarm/games/DarkForces/data.nix`

- Modify: source metadata only after successful prefetch

- Test: extraction and content assertions

- [ ] Prefer Steam app `32400` using the authenticated `fetchSteam` workflow.

- [ ] Discover and record the Windows depot ID, manifest ID, recursive file list, and fixed-output hash.

- [ ] Confirm whether TFE needs files beyond `DARK.GOB` from the owned depot.

- [ ] Remove DOSBox executables, launcher metadata, and unrelated Steam files.

- [ ] Assert that `DARK.GOB` exists with the expected case and path.

- [ ] Investigate GOG only after verifying its current product and installer metadata.

### Task 3: Add Launcher and Shortcut

**Files:**

- Modify: `hosts/home/monyarm/games/DarkForces/default.nix`

- Modify: existing Steam shortcut registration if appropriate

- Test: wrapper behavior

- [ ] Point TFE at immutable data using its supported data discovery/configuration mechanism.

- [ ] Set `TFE_DATA_HOME` or an equivalent writable XDG path for saves, settings, logs, and user mods.

- [ ] Ensure the wrapper does not mutate the Nix store.

- [ ] Register the shortcut only after direct startup reaches the Dark Forces main menu.

- [ ] Test one vanilla mission, audio, input, save/load, and a second launch.

### Task 4: Validate Mod Loading Without Adding a Fetcher

**Files:**

- Create: a mod derivation under `hosts/home/monyarm/games/DarkForces/mods/` only after selection

- Modify: `hosts/home/monyarm/games/DarkForces/default.nix`

- Test: TFE `Mods/` loading

- [ ] Verify TFE accepts a per-mod directory and ZIP in its `Mods/` location.

- [ ] Select one DF-21 mod with stable download, explicit provenance, and compatible TFE version.

- [ ] Record its archive hash and required layout before wiring it into Nix.

- [ ] Keep the mod optional and separate from the base launcher.

- [ ] Defer a DF-21-specific fetcher until stable URLs and archive conventions are established.

### Task 5: Keep Remaster Support Separate

**Files:**

- Modify: the game module only if an explicit Remaster source is added

- Test: separate remaster smoke test

- [ ] Do not mix Remaster HD assets into the classic data derivation.

- [ ] If pursued, add a second optional source and test its `darkpilo.cfg` and asset requirements independently.

## Verification

- Check for another Nix process with `pgrep -x nix` before evaluation or build.
- Build the game-data derivation and inspect that it contains original data without DOSBox launchers.
- Start TFE through the wrapper and verify the main menu and one vanilla mission.
- Confirm saves, settings, logs, and mods use only the writable user-data directory.
- Test the optional mod if Task 4 is implemented.
- Run `nix fmt` and `nix flake check`.
