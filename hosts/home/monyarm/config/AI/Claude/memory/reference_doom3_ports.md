---
name: reference_doom3_ports
description: Where to research DOOM 3 / RoE vs BFG Edition and the dhewm3 / RBDOOM-3-BFG ports, plus verified 2026-11-14 findings on content, gameplay, RBDOOM muzzle-flash restoration, mod support and versions
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-13T23:24:25.297Z
---

Reference for DOOM 3 (2004) + RoE vs DOOM 3: BFG Edition (2012) and their Linux ports. Findings verified 2026-11-14.

Sources: dhewm3.org (home, mods.html, FAQ), github.com/dhewm/dhewm3/releases, github.com/RobertBeckebans/RBDOOM-3-BFG (README + releases, in-tree `neo/d3xp/` and `base/def/`), pcgamingwiki.com Doom 3 and Doom 3: BFG Edition pages, en.wikipedia.org/wiki/Doom_3, doom.fandom.com/wiki/Doom_3:_The_Lost_Mission, moddb.com/mods/the-lost-mission.

Content:
- Original: Doom 3 base (27 levels) + RoE (12 levels, 6 new demons, SSG/Grabber/Artifact), sold as one package. BFG = D3 + RoE + The Lost Mission (8 levels, ~2-4 h) + Ultimate Doom (incl. Thy Flesh Consumed) + Doom II (with No Rest for the Living).
- BFG omits no campaign, but reworks/simplifies RoE and drops the 8-player CTF/modes (BFG MP = 4-player DM).

Gameplay deltas in BFG: armor-mounted always-on flashlight (original: hand-held, occupies weapon slot), excessive ammo/health, slower chaingun, no muzzle-flash lighting, texture/audio compression + color banding, brighter, unskippable cutscenes, no EAX; only 14 manual save slots shared across all three campaigns vs unlimited saves + quicksave in the original. Framerate: original caps ~62.5 fps, BFG ticks at 60 Hz (`com_engineHz`, fps-linked chaingun). Documented censorship only in BFG's bundled Doom/Doom II.

Muzzle flash on BFG data — RBDOOM restores it natively (verified 2026-11-14 in RBDOOM master):
- `neo/d3xp/gamesys/SysCvar.cpp:72` declares `g_muzzleFlash`, default `"1"`; it is exposed as a toggle in Game Options.
- `idWeapon::MuzzleFlashLight()` (`neo/d3xp/Weapon.cpp`, ~line 1562) bails only when `!lightOn && (!g_muzzleFlash || !muzzleFlash.lightRadius[0])`, and otherwise submits a real render-light def → flashes actually illuminate rooms.
- RBDOOM ships its own `base/def/weapon_*.def`; e.g. `weapon_pistol.def` has `flashRadius "120"` / `flashColor "1 0.8 0.4"` plus `smoke_muzzle "muzzlesmoke.prt"`.
- So BFG data + working muzzle-flash lighting needs no mod at all under RBDOOM. It also ships `weapon_flashlight.def` / `weapon_flashlight_new.def`, so the classic hand-held flashlight can be selected instead of the armor lamp.
- Not fixable by the engine: BFG's brighter base lighting and recompressed assets are baked into the data, and the 14-slot checkpoint save system stays.
- dhewm3 is irrelevant for BFG data (cannot read it); it only matters for 2004 D3/RoE + its mod scene.
- RBDOOM needs Vulkan or DX12 (OpenGL removed in 1.5.0), so GPU support must be confirmed before relying on it.

Mods: dhewm3 is the de-facto standard for 2004-era mods (Dentonmod, Sikkmod(+RoE), Perfected, Blood Mod, Hexen EoC dhewm3 edition, Rivensin, LibreCoop, and `d3le` = The Lost Mission for dhewm3). Binary-only DLL mods without GPLv3 source are dead. Vanilla BFG has no mod support. RBDOOM-3-BFG has modern modding (TrenchBroom, PBR, glTF2, .pk4) but cannot load old binary .dll mods. The Dark Mod is standalone since 2.x. The user does not care about legacy DLL mods or BFG multiplayer, so those losses are not blockers.

dhewm3: 1.5.5 (2026-06-08). 64-bit, SDL2/SDL3, OpenAL Soft EFX, widescreen + AR-independent GUIs, soft particles, ImGui menu, quicksave-slot cycling, high-fps `com_gameHz`, dhewm3-sdk. Stencil shadows only, no soft shadows (that is fhDOOM, unmaintained). Supports base + d3xp/RoE; does NOT read BFG data. Its own site warns Doom 3 netcode is RCE-insecure (don't play public MP).

RBDOOM-3-BFG: v1.6.0 (2025-05-10). 64-bit, DX12/Vulkan via NVRHI (OpenGL removed in 1.5.0), PBR, baked GI/IBL, soft shadow maps, HDR + ACES, TAA/SMAA, SSAO, optional classic flashlight. Requires BFG `base/` assets; cannot run original 2004 data. No built-in VR (separate fork).

Other ports: Chocolate DOOM-3-BFG (vanilla-faithful BFG fork), DOOM: BFA Edition (BFG fork with EAX/SMAA fixes), DOOM-3-BFG-VR, d3wasm (dhewm3 in browser). "Doom 3: Phobos" is a TC mod, not a port.

Verdict for someone owning all three SKUs: dhewm3 + original D3/RoE data for mods/quicksaves/visual mods; RBDOOM-3-BFG + BFG data for best visuals. Consistent with `project_boomer_shooter_engine_gaps.md`, which for this user settled on RBDOOM-3-BFG + BFG data (Steam 208200).
