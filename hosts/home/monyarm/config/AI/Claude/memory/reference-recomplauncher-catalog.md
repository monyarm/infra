---
name: reference-recomplauncher-catalog
description: "Verified 2026-11-17: recomplauncher.com/pc-catalog.json is a JSON catalog of 1825 recomp/decomp apps (origins incl. consoles), and it surfaced Flame (Dungeon Keeper 2), openQ4 (Quake 4), JA Enhanced/TaystJK, NeoRTCW, Q2Repro, opentyrian2000, NeoTS2, Brutal-OXCE"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-17T00:11:30.633Z
---

RecompLauncher (`recomplauncher.com`, repo `elripalda/RecompLauncher`) is a Tauri launcher that aggregates PC recomp/decomp projects. Verified 2026-11-17:

**Machine-readable catalog** — `https://recomplauncher.com/pc-catalog.json` (~5.5 MB, no auth) with keys `catalogVersion`, `platform`, `updated`, `apps`, `origins`, `developers`, `titles`, `banner(s)`, `labels`, `replaced`, `apps_min`, `boot_all`. **1825 apps.** `origins` covers `pc` plus consoles (`nes`, `snes`, `n64`, `gc`, `wii`, `wiiu`, `switch`, `switch2`, `gb`/`gbc`/`gba`, `nds`, `genesis`, `gg`, `saturn`, `s32x`, `dc`, `ps1`–`ps5`, `psp`, `xbox`, `x360`, `3ds`, `vb`, `arcade`, `amiga`, `cdi`, `other`). Adjacent endpoints: `pc-catalog-web.json`, `/trending.json`, `/games`, `/data/homebrew/`, `/schema/recomplauncher.json`, `/feed.xml`. The HTML pages (`/all`, `/trending`, `/whats-new`, `/soon`) are JS-driven, so scrape the JSON, not the HTML.

**Projects it surfaced that contradict earlier "no engine exists" conclusions:**
- `DiaLight/Flame` — **Dungeon Keeper 2** reimplementation (vs "DK2 has no engine at all"); check before finalising the KeeperFX plan.
- `themuffinator/openQ4` — **Quake 4** [Steam 2210] GPL source port (vs "no maintained port"); Steam data makes it fully automatable.
- `redsaurus/OpenJK` JA Enhanced and `TaystJK` — two Jedi Academy 6020 forks (Enhanced now in `openjk.md`).
- `klaussilveira/neortcw` — alternative RTCW engine to the wired one; `Paril/q2repro` — alternative to Yamagi for Quake II.
- `andyvand/opentyrian2000` — a *different* project from `opentyrian` (which `opentyrian.md` targets).
- `NeoTS2` — NEO Scavenger [248860], a Flash title; `Xilmi/OpenXcom` (Brutal-OXCE) — X-COM fork vs the repo's OpenXcom Extended.
- Recomp-of-titles-we-own-but-already-run-native: BioShock (7670), Serious Sam Classic (41050), Wolfenstein 3D x64 (2270).

**Why:** it is the single best catalog for finding recomp/decomp projects per title, and it has already falsified two assumptions used in planning.
**How to apply:** for any "is there a recomp/decomp/engine for X" question, fetch `pc-catalog.json` and match the `titles`/`apps` entries; treat earlier no-engine claims as needing re-verification against it.
