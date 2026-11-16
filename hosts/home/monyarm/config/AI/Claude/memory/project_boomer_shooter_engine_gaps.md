---
name: project-boomer-shooter-engine-gaps
description: Survey (2026-11-14) of owned games in games.list whose FOSS engine is already in pinned nixpkgs, the ones needing a custom derivation, the user's narrowed 2026-11-14 scope and revised 5-item work order, the check-nixpkgs-else-fetch-via-sources policy, and the Source titles excluded as already native
metadata:
  type: project
  origin: opencode
  modified: 2026-11-13T23:39:05.573Z
---

Follow-up engine survey (2026-11-14) over `games.list` (1044 lines: 888 Steam, 95 GOG, 39 Epic), after the TFE/TRX/OXCE work, looking for more boomer shooters to support. Written up as a plan/report at `/home/monyarm/.opencode/plan/boomer-shooter-engine-options.md`, which was updated with the narrowed scope on 2026-11-14 (see below).

Already covered in repo: Dark Forces (TFE), TRX, X-COM (OXCE), Wolf 3D (ECWolf), Duke3D World Tour + Shadow Warrior (Raze), Doom 1/2/64/Strife (GZDoom).

Cheap wins — engine already in pinned nixpkgs (owned) / store id:
- Half-Life (70), Opposing Force (50), Blue Shift (130) → `xash3d-fwgs`. Biggest win: one data fetch, three campaigns, plus owned GoldSrc mods (TFC, DoD, CS 1.6); no native Linux build otherwise. Caveat found later on 2026-11-14: only HL/TFC/Ricochet/Natural Selection ship Linux game libs — OpFor and Blue Shift need `hlsdk-portable` `opfor`/`bshift` libs and CS 1.6/CZ need `cs16-client`, so it is not purely a data-fetch job (see `reference_xash3d_fwgs_engine.md`).
- Doom 3 (9050) + Resurrection of Evil (9070) → `dhewm3`
- Return to Castle Wolfenstein (9010) → `iortcw`
- Wolfenstein: Enemy Territory (1873030) → `etlegacy`
- Jedi Outcast (6030) / Jedi Academy (6020) → `openjk` (Academy only; Outcast needs OpenJO — see the broader sweep memory)
- S.T.A.L.K.E.R. — `openxray` covers **only CoP (41700) and CS (20510)**; SoC (4500) is not supported by OpenXRay (pre-alpha, issue #392) and would need OGSR (Windows/D3D11) or Proton. CS also needs its extra `gamedata.zip`.

Engine exists but needs its own derivation: Quake II (2320, + RTX GOG copy) via Yamagi/vkQuake2 (small meson/cmake, data = `baseq2/*.pak`); Jedi Knight DF2 + Mysteries of the Sith (32380/32390) via OpenJKDF2 (SDL2, closest cousin to the Dark Forces work); Doom 3 BFG (208200) needs RBDOOM-3-BFG since dhewm3 cannot read BFG data.

No FOSS engine (Proton or nothing): Prodeus, Turbo Overkill, Dread Templar, Forgive Me Father 2, Boltgun, POSTAL: Brain Damaged, ULTRAKILL, Immortal Redneck, Super Buff HD, EMPTY SHELL, Deadlink, XIII Classic, Painkiller Overdose/Redemption, Rune Classic, Rise of the Triad (2013), Realms of the Haunting, Necromunda: Hired Gun, RoboCop: Rogue City, Quake 4 (GPL source, no maintained port).

Correction (2026-11-14, same day): **Serious Sam Classic TFE (41050) / TSE (41060) were wrongly listed above as "no FOSS engine"**. Serious Engine 1 is GPLv2 (Croteam open-sourced it) and community TFE/TSE builds exist; buildability not verified.

Not an engine-port target at all: Source titles (Portal, Portal 2, HL2 + episodes, TF2, CS:S, L4D2) already ship native Linux builds, so they need a desktop entry at most — no port project. See `reference_source_engine_availability.md`.

Settled 2026-11-16: Wolf 3D depot 2271 (manifest 4340236882319013272) **does** ship Spear of Destiny — `base/m1/{AUDIOHED,AUDIOT,CONFIG,GAMEMAPS,MAPHEAD,VGADICT,VGAGRAPH,VGAHEAD,VSWAP}.SOD` plus `base/m1/Spear.exe`. Whole depot is 49 files / 12.4 MB. Only the base SOD (`sod` data dir), **no** mission packs (`sd2`/`sd3`). Implemented 2026-11-16 (`games/ECWolf/spear-of-destiny.nix`), named "Wolfenstein: Spear of Destiny" and deliberately *without* a `steamAppId` (the 2270 store entry is already replaced by the Wolfenstein 3D entry), so it lands as a non-Steam shortcut. Keen Dreams/Commander Keen (Commander Genius) are platformers, not shooters.

Carmageddon Max Pack (GOG `carmageddon_max_pack`, `dethrace`) was in the original list but the user rejected it as out of scope on 2026-11-14: it is a car-combat racer, not a boomer shooter. Dropped from this survey; belongs to a separate genre survey.

Scope narrowed by the user later on 2026-11-14 (supersedes the original order; written into the plan file's §8 plus §1/§7 and Appendix A):
- Wanted now: **ET:Legacy**, **RealRTCW** (user explicitly named these two), **Doom 3 BFG via RBDOOM-3-BFG** (user wants BFG content *plus* the original muzzle-flash lighting; does not care about legacy DLL mods or BFG multiplayer), Half-Life via xash3d with the `valve` dir first. Re-stated by the user: from the GoldSrc list only the single-player games they own — HL, Opposing Force, Blue Shift; no TFC/CS/DoD/DMC/Ricochet, no GoldSrc mods, no HL:Source.
- Plan-file note kept as reference: the 55-branch `hlsdk-portable` map plus the `hlsdk-mega-build` manifest route, and the `hlsdk-portable` reuse trick (per-branch `src` override, ~10 lines).
- Skipped for now: **Carmageddon** (genre) and **STALKER/OpenXRay** (both CoP and CS) — explicitly deferred, not rejected on technical grounds.
- ET:Legacy is the cheapest item: nixpkgs `etlegacy` already `symlinkJoin`s an `etlegacy-assets` derivation that fetchurls `pak0/1/2.pk3` from mirror.etlegacy.com with pinned hashes → integration is just a flat game module + desktop entry, no `fetchSteam`, no sources entry, no asset-licensing problem.
- RealRTCW needs its own package (see `reference_idtech3_and_ecwolf_ports.md`).

Plan revision, still 2026-11-14 (later in the same session, user-directed):
- **Work order now 5 items: ET → RealRTCW → Doom 3 BFG → Half-Life → measure-compression** (plan §6).
- **Engine source policy (user instruction):** for each engine in the plan, check what the pinned nixpkgs ships; if it is out of date or absent, vendor it ourselves through `sources.*.toml` + the repo's `fetchGitTree` fetcher instead of relying on nixpkgs. Concrete plan entries added: plan §10 "package sources" (`sources.hl.toml` for `xash3d-fwgs` + `hlsdk-portable`, `sources.rtcw.toml` for RealRTCW), plan §11 "compression wiring".
- Version check against pinned nixpkgs (2026-11-14): `iortcw` 1.51c, `etlegacy` 2.86.2, `rbdoom-3-bfg` 1.6.0 (matches upstream v1.6.0) — all current enough; `xash3d-fwgs` is `0-unstable-2026-04-03` (rev `255c9bca`) while upstream `continuous` is 2026-11-10 → stale, so we fetch it ourselves; `realrtcw` is absent → own derivation.
- **Xash3D is handled as a folder with multiple files, "like how doom is handled"** (`games/Xash3D/`, modelled on `games/Doom/`), not a flat module — see `feedback_single_game_module_flat_file.md`.
- **`measure-compression.py` must gain Xash3D and TRX categories** (alongside the existing `--emulation/--renpy/--raze/--ecwolf` switches); user asked for both explicitly.
- The newer sweep candidates (Morrowind/OpenMW, Arx Fatalis, Fallout CE, KeeperFX, OpenJK, etc.) were explicitly skipped for now — see `project_games_list_engine_sweep.md`.

**Why:** avoids re-surveying the same list every time the question comes up, and records which candidates are nearly free vs. which need a real port, plus the agreed/narrowed order and the nixpkgs-vs-own-fetch rule.
**How to apply:** start with the revised 5-item order, not the original work order; nothing here was built or ownership-verified beyond `games.list`. Nixpkgs attribute names were confirmed only by directory lookup in the pinned nixpkgs. OpFor/Blue Shift are separate depots under app 70 and need the `direnv exec` owned-depot path, same as previous Steam fetches. See `reference_openxray_stalker_engine.md` for OpenXRay's data-path/CLI details and `reference_xash3d_fwgs_engine.md` for per-game library/run-flag details.
