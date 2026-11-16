---
name: feedback-single-game-module-flat-file
description: Single-game engine modules are one flat file under hosts/home/monyarm/games/, not a directory with default.nix; no mk<Engine> factories; Xash3D is an explicit exception (folder with multiple files, like Doom)
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-13T23:39:05.571Z
---

In `hosts/home/monyarm/games/`, a single-game engine is ONE flat file at the `games/` root (e.g. `OpenXcom.nix`, `DarkForces.nix`), not a directory with `default.nix`. Inline everything in that file (option + data fetch + wrapper + Steam entry). Only use a directory + helper when the engine genuinely hosts multiple entries (TRX: tr1/tr2/tr3 campaigns). Do not add `mk<Engine>` factory helpers for single-game engines.

**Exception named by the user (2026-11-14):** Xash3D-FWGS "will want to be handled as a folder with multiple files, like how doom is handled" — i.e. `games/Xash3D/` mirroring `games/Doom/` (engine conf + per-game-data subdirectories), not a flat `Xash3D.nix`. GoldSrc genuinely needs per-game data/lib entries (HL, OpFor, Blue Shift, mods), so it falls under the "engine hosts multiple entries" rule.

**Why:** Earlier I built `mkOpenXcom`/`mkDarkForces` factories and then folders with `default.nix`. User: "I dont understand why your openxcom needs mkOpenXcom, does the engine support multiple games and we're only handling one? Same with Dark Forces. I get it for TRX, since that handles multiple games." Then: "turn OpenXcom and DarkForces into single files, instead of a folder with a default.nix". The factory only pays off when the engine genuinely serves several games/campaigns. `hosts/home/monyarm/default.nix` does `imports = (autoImport ./config) ++ (autoImport ./games)` and `autoImport` (lib/imports.nix) handles both plain `.nix` files and directories with `default.nix`, so a folder buys nothing for one file.

**How to apply:** Prefer `games/<Engine>.nix` (like the existing `Desmume.nix`, `Minecraft.nix`, `YGOFab.nix`). Use `games/<Engine>/{default.nix,...}` and `mkTrx`-style factories for multi-entry engines (TRX, Doom, Xash3D). No `imports = autoImport ./.` inside a single-file module. If a second game for that engine is ever added, introduce the factory then.
