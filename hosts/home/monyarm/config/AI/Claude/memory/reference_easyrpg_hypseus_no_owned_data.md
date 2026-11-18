---
name: reference_easyrpg_hypseus_no_owned_data
description: "Verified 2026-11-17: the user owns no EasyRPG-runnable games (only the RM2k/2k3 tools; owned RM games are XP/VX/VX Ace = mkxp-z) and no LaserDisc/FMV titles for Hypseus Singe, whose nixpkgs version at the pinned rev is 3.0.2"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-17T01:16:24.637Z
---

Checked 2026-11-17 when the user asked whether any owned game can run through EasyRPG or Hypseus Singe. Both answers are "nothing owned", so neither is worth packaging for now.

**EasyRPG — zero data.** The user owns only the RPG Maker *tools* (RPG Maker 2000 [Steam 383730] and RPG Maker 2003 [362870]), not games made with them. Every owned RPG Maker *game* in the runtime survey is XP/VX/VX Ace (`Data/*.rvdata2`, plus `.rgss3a`), which is **mkxp-z** territory; EasyRPG reads RM2k/2k3's `.ldb`/`.lmt`. So EasyRPG would be a runtime with no data until an RM2k/2k3 game is bought.

**Hypseus Singe — zero data.** No LaserDisc/FMV titles in either owned list (checked for Dragon's Lair, Space Ace, Mad Dog McCree, Crime Patrol, Braindead 13, Thayer's Quest, Time Traveler, Cliff Hanger). nixpkgs does carry `hypseus-singe` (3.0.2 at the pinned rev, i.e. behind upstream 3.2.x), so it would be a pure data job if such a title is ever acquired.

**Why:** answer questions like this from the owned-library survey rather than re-deriving a game list, and don't plan work for a runtime the library cannot feed.
**How to apply:** revisit only when the user buys an RM2k/2k3 game or a LaserDisc/arcade FMV title.
