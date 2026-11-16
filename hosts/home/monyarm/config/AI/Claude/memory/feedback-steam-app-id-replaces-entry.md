---
name: feedback-steam-app-id-replaces-entry
description: In programs.steam.games, steamAppId is only for replacing an existing Steam entry; entries that should be extra shortcuts (e.g. Spear of Destiny from app 2270) must omit it
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T14:33:49.858Z
---

When adding a `programs.steam.games.*` entry, only set `steamAppId` when that entry is meant to *replace* the existing Steam library entry for that app. For an additional/derived shortcut that merely reuses an app's data, omit `steamAppId` entirely.

**Why:** the user stated "Specifying the appid is to make it replace a steam entry, and we already do that for 2270" — Wolfenstein 3D and Spear of Destiny share Steam app 2270, and only one entry may claim it. Without `steamAppId` the entry resolves to a CRC32-id shortcut with its own args (`--data sod`) instead.

**How to apply:** name the entry with the display title the user asked for (e.g. `WOLFENSTEIN_SPEAR_OF_DESTINY` with `name = "Wolfenstein: Spear of Destiny"`), keep the `fetchSteam` appId/depotId pointing at the shared app, and leave `steamAppId` out unless replacement is the explicit goal.
