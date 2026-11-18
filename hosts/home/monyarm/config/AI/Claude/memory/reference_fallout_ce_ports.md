---
name: reference-fallout-ce-ports
description: "Verified 2026-11-17: fallout2-ce does not support Et Tu/Restoration Project/Olympus 2207 (only Nevada/Sonora), fallout1-ce is separate ~60% done, and the circulating 291-line Et Tu \"diff\" is an unapplyable transcript paste that only proves booting"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T23:55:32.371Z
---

Verified 2026-11-17 from the `fallout2-ce` README and its GitHub issues:

- **Fallout 1in2 / Et Tu is fully unsupported, not partially.** It is listed under "not yet supported"; the maintainer (alexbatalov) answered on issue #166: "Et Tu uses many Sfall features and, most importantly, overrides to the hardcoded behaviour. The integration of Sfall is in progress, albeit slow."
- Same for the **Restoration Project** and **Olympus 2207** total-conversion mods.
- The only TC mods claimed to work are **Nevada** and **Sonora** (original versions).
- **Fallout 1 is a separate port, `fallout1-ce`** — alexbatalov reported it ~60% done with no deadline. Two ports, no 1-in-2 path.

The "locally patched diff" a contributor got Et Tu launching with (`alexbatalov/fallout2-ce/files/14094375/diff.txt`, 291 lines) was read in full: four hunks, all boot hacks — `mods/mods_order.txt` mod-dir + `scripts/` `dbOpen` loader in `src/game.cc`; `ddraw.ini [Misc] Movie1..N` filename overrides in `src/game_movie.cc`; Linux case-insensitive `glob()` path resolution with `[Aa]` masks in `src/platform_compat.cc`; `#if 0` around the `wmAreaInit` "Error loading Cities!" hard exit in `src/worldmap.cc`.
- **Not applyable as-is:** it is a pasted terminal transcript (a line split by the shell prompt mid-identifier) and one hunk calls `std::isletter`, which does not exist — it would not compile. It must be re-implemented from intent rather than `patch -p1`'d.
- It only proves the game **starts** ("I was able to start Fallout EtTu under linux", self-described as a dirty hack); no playable run, and it touches none of the Sfall / hardcoded-behaviour issues upstream names as the real blocker.
- The `#if 0` hunk also disables a sanity check that genuine FO2 relies on, so it is not safe for a shared build.

**Why:** this decides whether a Fallout 1/2 packaging job can deliver the "one unified Fallout" experience; it cannot.
**How to apply:** plan two independent derivations and do not promise Et Tu/RP/Olympus support. If the experimental patch is wanted, it is a separate optional package (`fallout2-ce-et-tu`) carrying rewritten hunks 1–3 only, verified along a boot → new game → first map → talk to NPC → save/load ladder, framed as "how far does it get", to be dropped once upstream supports Et Tu.
