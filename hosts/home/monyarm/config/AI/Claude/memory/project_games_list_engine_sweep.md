---
name: project-games-list-engine-sweep
description: "2026-11-14 games.list wide sweep beyond shooters: tiered FOSS-engine candidates (OpenMW, arx-libertatis, Fallout CE, KeeperFX, OpenJKDF2, reone…), rejected titles with reasons, biggest wins, and the user's decision to skip all of them for now"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-13T23:39:12.188Z
---

Broader `games.list` engine sweep from 2026-11-14 (after the boomer-shooter survey in `project_boomer_shooter_engine_gaps.md`; user asked "check games.list for anything else you can suggest open engines for"). No plan file of its own; results reported in chat only.

Tier 1 — engine already packaged in pinned nixpkgs:
- Morrowind (app 22320) → `openmw` (64-bit, modern renderer, no disk checks, big mod scene)
- Arx Fatalis (1700) → `arx-libertatis` (fixes widescreen/input breakage on the retail build)
- Jedi Knight: Jedi Academy (6020) → `openjk` (native Linux SP+MP)
- Tyrian 2000 (GOG) → `opentyrian` (trivial, data is free anyway)
- Dink Smallwood HD (GOG) → `freedink` (data free anyway)

Tier 2 — needs its own derivation:
- Fallout 1 + 2 (38400 / 38410) → `alexbatalov/fallout1-ce` / `fallout2-ce` (decompiled engines: 64-bit, high-res, bugfixes)
- Dungeon Keeper Gold (GOG `dungeon_keeper`) → KeeperFX (GOG build is a bad DOSBox wrapper; `keeperfx` was NOT in the pinned nixpkgs on 2026-11-14)
- Quake II (2320) → Yamagi (already deferred in the other survey)
- Jedi Knight DF2 + MotS (32380 / 32390) → OpenJKDF2
- Jedi Outcast (6030) → OpenJO (the `openjk` package is Academy-only)
- Serious Sam Classic TFE/TSE (41050 / 41060) → Croteam's GPLv2 Serious Engine; community TFE/TSE builds exist but buildability unverified (this corrected the earlier "no engine" claim)
- KOTOR + TSL (32370 / 208580) → `reone`, a WIP reimplementation — watch only, not buildable as a game yet

Rejected with reasons:
- RollerCoaster Tycoon Deluxe — OpenRCT2 needs RCT2 assets; RCT1 alone is insufficient
- OpenTTD, Warsow — these *are* the open engines already
- BG / IWD / Planescape EE — GemRB supports the originals but the EEs already run natively, so no gain
- Arena — OpenTESArena is unpackaged and far behind Daggerfall Unity
- No FOSS engine at all: NWN Diamond, Legacy of Kain: Defiance, Warcraft II, SimCity 4, F.E.A.R., POSTAL Classic, Tomb Raider Legend/Anniversary/Underworld

Biggest wins identified: Morrowind/OpenMW, Arx Fatalis, Dungeon Keeper + KeeperFX, Fallout CE.

User decision, 2026-11-14 (same session): "as for the latest ones you found, we're gonna skip them for now" — nothing in Tier 1/Tier 2 is scheduled; the shortlist is kept only for a later pass. The current work order stays the 5 items in `project_boomer_shooter_engine_gaps.md` (ET → RealRTCW → Doom 3 BFG → Half-Life → measure-compression).

**Why:** the same "which owned game has an engine worth using" question recurs; this records the per-title verdicts so the sweep is not repeated — and the skip decision, so the list is not re-proposed as work.
**How to apply:** nothing here was built or launch-tested as of 2026-11-14; KeeperFX and Fallout CE data layouts are unverified until a first run. Confirm nixpkgs attribute names by directory lookup in the pinned nixpkgs before packaging. Do not schedule these unless the user reopens the topic.
