---
name: reference_source_engine_availability
description: "Verified 2026-11-14: no open-source Source/Source 2 engine exists (Portal/Portal 2 already ship native Linux builds), Source SDK 2013 is mod-only, and the rule for which games can be replaced by a FOSS engine"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-13T23:30:44.647Z
---

Question answered 2026-11-14: is there an open-source engine for non-GoldSrc Source (e.g. Portal)? No — and none is needed.

Verified facts (2026-11-14):
- Portal (app 400) and Portal 2 (app 620) both report `platforms.linux: true` in the Steam appdetails API. Valve shipped native Linux builds in 2013 and they still work, so supporting them is install-and-run: no fetch, no wrapper, no derivation.
- Valve open-sourced GoldSrc only because it is Quake-derived (GPL obligation); the free-source line stops there.
- Source 1 engine tree was never released and no FOSS reimplementation exists or is realistic. Source 2 is closed too.

Things people mistake for an engine:
- Source SDK 2013 (`ValveSoftware/source-sdk-2013`): official and open, but builds *mods*, only for games with an SDK branch (HL2, Episodic, MP). No official Portal branch; community "Portal SDK" forks are mod bases, not engines.
- `nillerusr/source-engine`: 2017 engine tree leaked in 2020, modified, ~2.3k stars, still pushed (2025-11-25). Unlicensed leaked code — not distributable, never going into nixpkgs.
- RTX Remix Portal: NVIDIA visual overhaul, Windows-only, closed.
- Mapbase: SDK 2013 fork for mappers, not an engine.

General rule for the library: an engine can only be replaced when its source got out — id Tech 1-4, Build, GoldSrc, X-Ray, Doom 3, Serious Engine. Source, Source 2, Unreal and every modern proprietary engine are native-build-or-Proton, never "port it".

Practical consequence: Source titles in the library (Portal, Portal 2, HL2 + episodes, TF2, CS:S, L4D2) are already native Linux. Any work there is a desktop entry or launch options (`-novid -console`), not an integration project. Untested as of 2026-11-14: whether the old Linux builds actually launch on this machine (known library-drift issues; worth a smoke test).
