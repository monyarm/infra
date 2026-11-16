---
name: owned-library-runtime-categories
description: 2026-11-16 PCGW-derived survey of the owned library by runtime (DOS/DOSBox 31, Flash/AIR 13, Java 3, RPG Maker 14, GameMaker 19, XNA 17, AGS 3, Win9x 16…), the HTML deliverable path, and the repo gaps each category implies
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T19:13:56.328Z
---

Owned-library **runtime-category survey** (2026-11-16), built from PCGamingWiki engine/date data over all Steam/GOG/Epic/Maxima titles, excluding Unity (248), Godot (6), Electron/NW.js, and everything already handled in the repo or in `.claude/plans` (ScummVM incl. Wintermute, GZDoom, ECWolf, Raze, TFE, TRX, OXCE, Xash3D, DevilutionX, Emulation collections, planned Ren'Py catalogue, Daggerfall).

Deliverable: `/home/monyarm/.opencode/plan/owned-games-runtime-categories.html` — 130 cards across 9 sections, cover image on every card with a lettered placeholder fallback (all images verified 200). Written there only because plan mode blocked other writes; user may relocate it.

Counts: DOS/DOSBox 31 · Flash(SWF)/Adobe AIR 13 · Java(JAR) 3 · RPG Maker(RGSS) 14 · GameMaker 19 · XNA/FNA/MonoGame 17 · AGS 3 · Windows 9x/Win16 era 16 · misc one-offs 14 (LÖVE, Visionaire, Multimedia Fusion, Monkey X, Solar2D, BlitzMax, Playground SDK, Marmalade, Dinky, Heaps).

Repo gaps this exposes:
- **No DOS runtime at all** — `buildDosBox` in `lib/fetchers/dosbox.nix` has zero users; only `config/Dosbox.nix` + `Steam/boxtron.nix` exist. Several DOS titles have better FOSS engines instead: Tyrian → OpenTyrian, Dungeon Keeper → KeeperFX, Carmageddon → dethrace.
- **No Flash/AIR runtime** (no ruffle/swf packaging), **no Java interop** (Slay the Spire + Mindustry = libGDX, Spiral Knights = LWJGL).
- **RPG Maker is editor config only, no runtime** — mkxp-z/EasyRPG would be the path. GameMaker has no FOSS runner.

Correction (2026-11-16, user was right): **Double Dragon Trilogy (Steam 314150) IS already wired up** — `hosts/home/monyarm/games/Emulation/arcade/double-dragon.nix` fetches the depot via `fetchSteam` and extracts with game-extraction-toolbox (`--task ddragontrilogy`). An earlier note claiming it was the one unhandled DotEmu wrapper was wrong; do not repeat it.
