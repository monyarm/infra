---
name: project-df-ufo-steam-depot-contents
description: Verified Steam depot + manifest facts for Dark Forces (app 32400) and X-COM UFO Defense (app 7760), including DARKPILO.CFG and DARK.GOB/LFD layout
metadata:
  type: project
  origin: opencode
  modified: 2026-11-13T18:08:11.788Z
---

Verified Steam depot contents (manifest-only listing, 2026-11-13) for the two non-Tomb-Raider engine plans:

- **32400 Star Wars Dark Forces** (TFE) — depot 32401, manifest `32401_2706075311504202822`, 85 files. It is a DOSBox-wrapped upload, not a raw DOS tree: `DosBox/` + `dosbox.conf`, and the actual game under `Game/` — `Game/DARK.GOB` is **14.2 MB** (not ~30 MB as earlier notes assumed), with the cutscene `Game/LFD/*.LFD` files (48 of them, e.g. `1E.LFD`, `AGENTMNU.LFD`) that must sit beside `DARK.GOB`. The depot ships the old DOS `JEDI.CFG`, **not** `DARKPILO.CFG`.
- **7760 X-COM UFO Defense** (OXCE) — depot 7761, manifest `9064227437018934890`, 858 files, plain loose DOS layout: `GEODATA/`, `GEOGRAPH/`, `MAPS/`, `ROUTES/`, `MISSDAT/`, `SOUND/` + `SOUND.CFG`, `GAME_1`..`GAME_10`, `MVOL.DAT`, `patch.dll`, DOS4GW/dosbox extras. No unpacking trickery needed.

`DARKPILO.CFG` is TFE's own save/agent container (`PCF` signature, version 0x12, 14 agent slots — `TFE_DarkForces/agent.cpp`), resolved from user docs → migrated from program data → copied from source data → generated. Never fetch it from a depot and never write it into store game data.

**Why:** These depot facts fed the now-deleted `.claude/plans/{dark-forces-tfe,xcom-oxce}.md`; the earlier 30 MB DARK.GOB figure and a guessed manifest for X-COM were both wrong.

**How to apply:** Reuse the depot/manifest ids above for `fetchSteam` work on these two games; when packaging Dark Forces, extract `Game/` (GOB + LFD) rather than assuming a flat DOS root.
