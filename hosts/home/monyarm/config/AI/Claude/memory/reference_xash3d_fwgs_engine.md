---
name: reference_xash3d_fwgs_engine
description: "Where to research Xash3D-FWGS and verified 2026-11-14 findings: fork-vs-original vs Valve hl_linux/XashXT/HL:Source, rolling continuous builds, per-game libs, the complete hlsdk-portable branch↔game mapping, mega-build manifest, renderer and multiplayer limits"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-13T23:27:27.907Z
---

Xash3D-FWGS (github.com/FWGS/xash3d-fwgs) research, verified 2026-11-14, as a replacement for the stock Half-Life/GoldSrc executable on Linux.

Where to look:
- `Documentation/` in the repo: `supported-mod-list.md`, `not-supported-mod-list-and-reasons-why.md`, `extensions/steam-broker.md`, `goldsrc-protocol-support.md`, `environment-variables.md`, `hd-textures.md`, plus porting/port-status pages.
- GitHub API for tags (`v0.20` is a commit dated 2019-12-03) and `releases.atom` for the rolling `continuous` build tag; snmetamorph.github.io status-update posts (Dec 2024/2025) for engine news.
- Companion repos: `FWGS/hlsdk-portable` (game libs + `wiki/Mods`, ~60 branches), `FWGS/hlsdk-mega-build` (machine-readable `manifest.yml`: branch, repo, games[], download method moddb/steam, sha256, unpack method — plus prebuilt archives; use this instead of hand-writing 55 derivations), `Velaron/cs16-client`, `FWGS/steam-broker`.

Lineage / "which engine?" disambiguation (2026-11-14):
- Unkle Mike's original Xash3D is abandoned (~2013), Win32-first, stock PAK only, GL (+D3D variant), no Steam HL support. FWGS is a heavily modified fork and the only maintained GoldSrc engine: SDL2/SDL3 one code path, Linux/BSD/Haiku/Emscripten/Android/iOS/Vita/Switch (macOS dropped 2025), HLSDK 2.5 Steam support, PK3/ZIP VFS + HD texture mounts, PNG/KTX2/DDS, FFmpeg video, IPv6, headless `xashds`, GL/GLES/soft/null renderers.
- The real "other Half-Life engine" is Valve's official `hl_linux` binary shipped with Steam: 32-bit x86, libs only for the four game dirs Valve recompiled, no mod-side maintenance — the thing xash3d replaces.
- XashXT 0.65 is Unkle Mike's SoHL-based mapper toolkit (not an engine), abandoned; upstream points to PrimeXT (SNMetamorph); both are SDKs running on xash.
- Half-Life: Source (app 280) is Valve's Source port — different engine, breaks GoldSrc mods, no reason to install.
- "Xash3D FWGS Old Engine" / EZX / Vita / Switch builds are the same FWGS code, not alternatives. No other independently maintained GoldSrc engine was found.

Verified facts:
- GPLv3, hence Steamworks cannot be linked (hence the broker). No stable releases: last versioned tag `v0.20` (2019-12-03), shipping channel is the rolling `continuous` tag (build 4241, 2026-11-10); weekly commits, ~2.9k stars.
- Game dirs are the Steam depot folder names: `valve`, `gearbox`, `bshift`, `cstrike`, `tfc`, `dod`, `dmc`, `ricochet`.
- Valve's Linux x86 libs load as-is for HL, TFC, Ricochet and Natural Selection. CS 1.6 and CZ stock `client.dll` is VGUI2 → use `cs16-client` (i386 build); DoD 1.3 → `dod13-client`; TFC optionally `tf15-client`. 64-bit/ARM always requires recompiled game libs.
- Why OpFor/Blue Shift need rebuilds (2026-11-14): a GoldSrc game = engine binary + game code (`dlls/hl.so` server, `cl_dlls/client.so` HUD/prediction). Valve's 2013 Linux port recompiled game libs only for `valve`, `tfc`, `dmc`, `ricochet` (plus server-side CS/DoD). The `gearbox/` and `bshift/` depots still ship **Windows PE `.dll` only** — Gearbox never rebuilt them for Linux and never released their source, and the Linux loader cannot `dlopen` a PE file, so the game code must be compiled from HLSDK. `hlsdk-portable` is Valve's HLSDK patched for modern compilers/platforms, one branch per game (`master` = HL, `bshift`, `opfor`, ~60 branches for mods).
- Why the `opfor` branch is flagged unstable: OpFor's game logic (gear grinder, friendly marines, rope, op4 weapons) was never open-sourced, so the branch is a community reimplementation over HLSDK rebuilt from observed behaviour — gaps and crashes are possible and each OpFor/Blue Shift install needs a real launch test. The `bshift` branch is not flagged unstable by upstream. Half-Life itself ships clean.
- Retail game ↔ lib summary: HL(70) `valve`; OpFor(50) `opfor`; Blue Shift(130) `bshift`; TFC(20) Valve stock, `tf15-client` optional; CS 1.6(10) `cs16-client` + ReGameDLL_CS; CS:CZ(80) `cs16-client` (Deleted Scenes unsupported); DoD 1.3(30) `dod13-client`; DMC(40) and Ricochet(60) Valve stock; HL:Source(280) out of scope.
- Complete branch↔game mapping (55 branches): `sohl1.2` Spirit of Half-Life SDK; `CAd` Cleaner's Adventures; `theyhunger` They Hunger trilogy; `decay-pc` Half-Life: Decay (PS2 co-op on PC); `ps2hl` PS2 HL port; `aom`/`aomdc` Afraid of Monsters (+Director's Cut); `asheep` Azure Sheep; `biglolly`; `blackops`; `bubblemod`; `caseclosed` (Case Closed + Bloody Pizza: Vendetta + Borderlands); `counter-life`; `cracklife`; `CLAnniversary`; `clcampaign`; `echoes`; `eftd`; `half-secret`; `half-screwed`; `halloween`; `hltopdown`; `hl_urbicide`; `noffice`; `poke646`/`poke646_vendetta`; `rebellion`; `residual_point` (Residual Point + Residual Life); `redempt`; `sci`; `sewer_beta`; `thegate`; `tot`; `visitors`; `zombie-x`; `aghl` Adrenaline Gamer; `bot10`; `hlfixed`/`opforfixed` fixed-lib variants; `dmc` (also ThreeWave CTF); `xen-warrior` uses `sohl1.2` with a `XENWARRIOR` build flag.
- Branches living in other repos: `featureful`, `field_intensity_1.7`, `induction`, `intense_force`, `sum` → `FreeSlave/halflife-featureful`; The Last Bullet → `fwgs` branch of `GT-Project-Cat/The-Last-Bullet-Updated-Code`.
- Work with vanilla HL libs (no compile, drop folder beside `valve/`): ~650 upstream entries (257 big SP mods, 47 unfinished, 23 mappacks, 302 single maps, 6 minor incompatibilities); e.g. USS Darkstar, Uplink, Caged.
- Already Linux-native, no branch: Cold Ice Remastered, Delta Particles, Gang Wars, Induction 1.4, Intense Force, Invasion, Half-Rats: Parasomnia/Redridge, Mortal Kombat, Natural Selection, X-Half-Life DeathMatch, Zombie Panic!, CS 1.6 stock.
- `mobile_hacks` (bundled on mobile only): AoM, Big Lolly, Blue Shift, Half-Secret, Case Closed, Bloody Pizza, Borderlands, Induction 1.2, Absolute Redemption, Sewer beta, Times of Troubles, Urbicide.
- Abandoned: Half-Life: Gravgun, Paranoia, Quake Remake, XashXT. CS-based CSMoE ships its own xash build.
- Per-case tricks: extra `.wad` files, `liblist.gam` gamedll path fixes, `fps_max 60`, `sv_validate_changelevel 0`, removing `secure 1`.
- Renderers in mainline: GL 1.x, GLES1/2 via `gl2_shim`, software, null. No Vulkan (only third-party `HLSources/Half-Life-RTX-clone`), no normal mapping; HD support is TGA texture replacement only.
- Other engine features: VFS with pk3/pk3dir/zip and `fs_mount_hd/_l10n/_addon/_lv`, BSP2 at runtime, Ogg/Opus/MP3, Opus voice chat, multi-master, `scripts/xashds@.service`, GoldSrc protocol via `connect ip:port gs` plus steam-broker.
- Input/display: `m_rawinput` defaults to 1 (SDL relative mouse), joystick/touch support, `refState.wideScreen` and `hud_scale`.
- Multiplayer/Steam: no VAC; stock servers reject with "Steam validation rejected" unless running Reunion/dproto, and some ban "fake clients". No achievements, overlay, cloud or friends; auth only through the broker. Not bit-exact vanilla; HiDPI/scaling complaints.

How to run:
- `xash3d -game <dir> -basedir <root>`; env `XASH3D_GAME`, `XASH3D_BASEDIR`, `XASH3D_RODIR`, `XASH3D_EXTRAS_PAK1/2`; lib overrides `-clientlib cl_dlls/client.so -dll dlls/hl.so`; `-rodir` for read-only assets.
- Writes `<basedir>/<gamedir>/config.cfg`.

**Why:** Packaging Half-Life family engines needs the per-game library story up front — the "one data fetch, three campaigns" assumption breaks for OpFor/BS/CS.
**How to apply:** Re-check the tags/releases API before pinning (rolling `continuous` tag, no stable); treat anything here marked unverified (Cry of Fear, HRTF) as unknown, not settled. nixpkgs' `hlsdk-portable` is a plain waf build pinned to a fixed rev, so a per-branch lib is an override with a different `src` rev (~10 lines), not a new package; only `opfor`/`bshift`/`cs16-client` etc. actually need one. None of the branches were compiled or launch-tested as of 2026-11-14.
