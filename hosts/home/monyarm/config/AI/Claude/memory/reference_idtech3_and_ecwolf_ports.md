---
name: reference_idtech3_and_ecwolf_ports
description: Where to research iortcw (RTCW), RealRTCW, ET:Legacy and ECWolf, plus verified 2026-11-14 findings on data layout, RealRTCW build/packaging, versions, features, mod compatibility and MP status
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T14:33:49.964Z
---

Research pointers + verified findings (2026-11-14) for Wolfenstein-lineage FOSS ports. They are commonly confused but run different games: iortcw = Return to Castle Wolfenstein (2001, id Tech 3); RealRTCW = a total-conversion-style overhaul built *on* iortcw; ET:Legacy = Wolfenstein: Enemy Territory (2003, id Tech 3, free standalone MP); ECWolf = Wolfenstein 3D / Spear of Destiny (1992, pre-Doom raycaster).

**Primary sources**
- iortcw: https://github.com/iortcw/iortcw (README + /tags). RealRTCW: https://github.com/wolfetplayer/RealRTCW (repo + /releases API), releases also mirrored at the iortcw-linked page
- ET:Legacy: https://www.etlegacy.com (about/download/blog), wiki FAQ, wiki Compatible-Mods, wiki Changelog, https://github.com/etlegacy/etlegacy
- ECWolf: https://github.com/ECWolfEngine/ECWolf (docs/changelog), https://maniacsvault.net/ecwolf/ (download, notes.php release notes, multiplayer.php), wolf3d.net mod listings
- Steam depot / manifest inspection for game assets: DepotDownloader/steamcmd `-manifest-only`

**iortcw (RTCW SP + MP)**
- Two binaries ioWolfSP/ioWolfMP (`.x64`). Data into `main/`: SP `pak0.pk3` + `sp_pak1-3.pk3`; MP `mp_bin.pk3`, `mp_pak0-5`, `mp_pakmaps0-6`; then overlay `patch-data-141.zip`.
- Latest tag v1.51c (2019-03-16); last commit 2024-05-26 (FreeBSD/nanosleep only) -> dormant.
- 64-bit, SDL 1.2, OpenAL (HRTF), Ogg/Opus, Mumble VoIP, PNG textures; GL 1.1 + optional rend2; widescreen via `cg_fixedAspect 2`/`cg_fixedAspectFOV`, `r_mode -2`; FOV + `com_maxfps` (movement is frame-rate linked, keep <=125). No Vulkan.
- Original RTCW mods/QVMs still load but 64-bit needs 64-bit mod builds; HD texture packs work. RealRTCW 5.44c released 2026-08-29.
- MP: id master gone, no replacement master in-engine -> direct connect; sparse evening servers, rest bots. rtcwcoop.com runs a co-op master.
- No anticheat: PunkBuster was stripped from the GPL source and discontinued in 2011.

**RealRTCW packaging (verified 2026-11-14)**
- GitHub `wolfetplayer/RealRTCW`: "RealRTCW mod based on iortcw engine", C, GPL-3.0, active (pushed 2026-11-10). Tags seen: 5.44c (newest), 5.4, 5.3.
- Releases carry **no binaries and no assets** (asset list empty) — it must be built from source, unlike iortcw releases.
- Build: plain `Makefile` (not CMake/meson), `HOWTO-Build (linux).md` / cygwin / msys2 guides in-tree. Needs FFmpeg 8 and SDL3 (reached through `sdl2-compat`) — so the derivation must pin newer libs than iortcw's SDL1.2 requirement.
- Mod content lives in the repo itself: `main/` (camos, loadouts, maps, scripts, text, ui, `realrtcwdefault.cfg`) and `main_custom_maps/`, so it is a source build + retail data, not data-only.
- Still requires retail RTCW data from Steam app 9010: `pak0.pk3` + `sp_pak1-3.pk3`. No `fetchSteam` alternative exists for the mod's own content.
- Unverified until a first run: RealRTCW's exact data-directory expectations (whether the repo's `main/` overlays or replaces `main/`, and where the retail paks must land).

**ET:Legacy**
- GPL ET 2.60b engine + the new "Legacy" mod. Data: `etmain/pak0.pk3` mandatory, `pak1/pak2` for some third-party mods. Assets are free from Splash Damage but not redistributable (FAQ).
- Very active: 2.86.0 on 2026-09-19, 2.86.2 on 2026-10-11.
- 64-bit, SDL2, raw mouse, OpenGL + renderer2 (XreaL-derived); Vulkan only appears in the unreleased 2.8x changelog, not stable. Omni-Bot + WolfAdmin bundled, Lua, auto-update, 64+ player servers.
- Mod compat splits on bitness: 64-bit client only joins 64-bit mods (Legacy, ETJump, ETRun, N!tmod); Jaymod/NoQuarter/ETPub/silEnT are 32-bit -> use the 32-bit client. ETPro works server-side only.
- Healthy multiplayer: own master `master.etlegacy.com`, official test server; ~556 players / 647 ETL clients when checked.
- No anticheat (FAQ calls it impractical; PB impossible); fragile macOS; assets not shippable.
- Packaging note (2026-11-14): pinned nixpkgs `etlegacy` already `symlinkJoin`s `etlegacy-assets`, which fetchurls `pak0.pk3`/`pak1.pk3`/`pak2.pk3` from `https://mirror.etlegacy.com/etmain/` with pinned hashes — so no fetchSteam/owned-depot step and no local asset handling is needed.

**ECWolf**
- Wolf4SDL-based with ZDoom-ish modding; still an 8-bit software raycaster only (no GL/Vulkan).
- One binary for all games; data in `~/.config/ecwolf/`: `wl6`/`wl1` (Wolf3D), `sod`/`sd2`/`sd3` (Spear + mission packs), `n3d`/`sdm` (Super 3D Noah's Ark).
- `--data <name>` is a **dataset selector** (the game's file extension, e.g. `wl6`, `sod`) that skips the launcher dialog — not a directory flag. Data paths are searched recursively, so files dropped flat into `~/.config/ecwolf/` work as well as per-game subdirs.
- Steam's "Wolfenstein 3D" app (2270) ships both datasets from depot 2271: `base/*.WL6` and `base/m1/*.SOD` (8 files: AUDIOHED, AUDIOT, GAMEMAPS, MAPHEAD, VGADICT, VGAGRAPH, VGAHEAD, VSWAP, total ~3 MB). The depot has **no** `sd2`/`sd3` mission-pack data — only base Spear of Destiny.
- Latest stable 1.4.2 (2025-09-14); active (1.5pre in git, nightlies).
- 64-bit, SDL2, widescreen incl. 32:9, aspect correction, arbitrary-res textures, automap, unlimited saves, adaptive frame rate (no 70 Hz lock), WASD+mouse. LAN co-op/DM up to 11 via P2P lockstep — no internet play, no master server.
- Mods: PK3/WAD/DECORATE/MAPINFO; vanilla map sets run (Spear Resurrection conversions, DHW Totengraeber Mapset). Most Wolf4SDL *source-fork* mods do NOT run.
- Blake Stone, Corridor 7, Operation Body Count, ROTD/ROTT only *boot* behind `ShowPreviewGames` — not playable, planned for 2.0/3.0; Mac Wolf in 2.0. Chex Quest is Doom-engine, irrelevant.
- Fidelity: same engine logic and vanilla-accurate by policy, but intentionally fixes frame-rate bugs (e.g. Hitler fireball speed).

**Unverified at the time**: exact high-refresh caps in ECWolf, whether rend2 ships enabled in iortcw releases, 32:9 behaviour under iortcw, RealRTCW data-dir layout.
