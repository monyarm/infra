---
name: reference_owned_linux_native_sweep_2026_11_17
description: "2026-11-17 PCGW-based sweep of the owned library for Linux builds: 345 rows with only ~12 needing repo work, the second-pass mod-support targets (Stardew+SMAPI and Slay the Spire accepted into a basic native-games plan file), and the newly widened ask to include PCGW hacky tweaks (data edits, hex patches, custom mods)"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-17T01:31:14.152Z
---

Survey done 2026-11-17 by intersecting the owned list against PCGW's `dates`/platform column: **345 owned titles have a Linux build listed**, but that number is inflated because PCGW records every platform a game ever shipped on (dead Loki ports, delisted builds). Roughly 340 need no repo work at all; the real targets are ~12 and are all "wrap a broken bundled runtime / ancient SDL" jobs, not engine ports.

**Worth handling — bundled JRE / Mono / LWJGL natives:** Slay the Spire [646570] (bundled JRE), Spiral Knights [99900] (LWJGL Java + launcher stub), Hacknet [365450] and Else Heart.Break() [400110] (bundled Mono).

**Worth handling — Loki-era / SDL1 natives:** Rune Classic [210950], POSTAL [232770] + POSTAL Classic and Uncut (GOG, SDL1 Loki build), Quake II [2320] (already covered by the yamagi-quake2 plan). Usual fix is an `sdl12-compat` preload, not a rewrite.

**Owned FOSS games whose store copy is pointless:** OpenTTD (GOG — the build *is* OpenTTD, `pkgs.openttd` needs no assets), Warsow (GOG, in nixpkgs), Mindustry [1127400] (libGDX, already in nixpkgs).

**Native, config/shortcut work only:** Baldur's Gate EE / BG2 EE / IWD EE / Planescape EE (Beamdog Linux builds → GemRB pointless), Neverwinter Nights EE [704450] + Diamond on GOG, Prey [480490]. Serious Sam 3 / Fusion / SS4 are native and need nothing (listed only to close the loop).

**False positives, do not chase:** Rocket League [252950] (Linux dropped 2020), PAYDAY 2 [218620] (deprecated upstream); Fallout [38400], Tomb Raider I [224960], Dark Forces [32400], Tyrian 2000, Biing!, Keen Dreams, Al-Qolim/DOS-era rows (PCGW is listing the source-port/freeware Linux build, not a Linux build of the store product); and genuinely native titles needing nothing — Chroma Squad, Evoland, Axiom Verge, Owlboy, Celeste, Dead Cells, Stardew, Terraria, Hollow Knight, FTL, Crypt of the NecroDancer, Undertale, Hotline Miami 1/2.

**Second pass, 2026-11-17 — mod support as a separate axis** (after the user rejected "it runs natively, so nothing to do"): native titles with a real mod ecosystem are targets even when the port itself is fine.

- **Stardew Valley [413150]** — SMAPI, Linux-native, the highest-value target by a wide margin (mods must not be hand-copied into the store path; needs a proper entry point).
- **Slay the Spire [646570]** — ModTheSpire + BaseMod; the cheapest, because the JRE wrapper and the mod loader are the same wrapper.
- **Terraria [105600]** — tModLoader (separate free Steam app 1281930), nearly free: one data dir.
- **Celeste [504230]** — Everest, lives in the game dir and writes its own saves/config (same writable-runtime-dir shape as the engine plans).
- **Hollow Knight [367520]** — Modding API / Lumafly, installs into `Managed/`.
- **Cheap, low payoff:** Crypt of the NecroDancer [247080], FTL [212680] (Slipstream), Mindustry [1127400].

**PCGW-tweak-only class** (no module needed): launch-option fixes via `programs.steam.games.<KEY>.args` in `shortcuts.vdf.nix` — Portal 1/2, the BG EE family, NWN EE, Prey, Serious Sam 3/Fusion/SS4. Worth a sweep, not individual plans.

**User direction, 2026-11-17:** accepted the mod-support targets — Stardew Valley and Slay the Spire are to be added to a **new plan file for native games, which is just a basic list for now** — and widened the ask: the list should also cover titles where PCGW recommends editing game data files, hex-editing the executable, custom/hacky mods and similar, with suggestions for those. That hacky-tweak class is the axis to research next; nothing from it has been collected yet.

Earlier-proposed alternative next step (one small plan covering the Java/Mono/old-SDL group) was superseded by the above.
