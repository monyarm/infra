---
name: project_keeperfx_wargus_openjkdf2_plans
description: "2026-11-17 plan-mode designs written to /home/monyarm/.opencode/plan/ (incl. pokemon-infinite-fusion, cosmo-cosmic-adventure, drl, srb2, solarus-zsdx): keeperfx, stratagus-wargus-war1gus, openjkdf2, opentyrian, dethrace, reflectionhle (Bio Menace only now), opentesarena, openjk (incl. JA Enhanced), arx-libertatis, relive, yamagi-quake2, sonic-mania, openmw, fallout-ce, dusklight, openq4, commander-genius, pif — nothing implemented yet; DK2 dropped after Flame verdict; Keen Dreams settled to Commander Genius; Cosmo as a Commander Genius option; plus the open question of relocating them into the repo's .claude/plans"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-17T01:17:03.534Z
---

Plans written 2026-11-17 in `/home/monyarm/.opencode/plan/` (Plan mode only allowed writes there) — nothing implemented yet: `keeperfx.md`, `stratagus-wargus-war1gus.md`, `openjkdf2.md`, `opentyrian.md`, `dethrace.md`, `reflectionhle.md`, `opentesarena.md`, `openjk.md`, `arx-libertatis.md`, `relive.md`, `yamagi-quake2.md`, `sonic-mania.md`, `openmw.md`, `fallout-ce.md`, `dusklight.md` (low priority — Wii disc encryption is the blocker), `openq4.md`, `commander-genius.md`, `pokemon-infinite-fusion.md`, `cosmo-cosmic-adventure.md`, `drl.md`, `srb2.md`, `solarus-zsdx.md`.

**Location question (raised 2026-11-17, unanswered by the user):** the user asked whether these plans can live in the repo's plan folder instead. Answer given: in Plan mode the agent can only write to `/home/monyarm/.opencode/plan`, because `.claude/plans/` is inside the repo and writing there is a repo modification. Proposed first action in Build mode: either `git mv` the files into `.claude/plans/` (consistent with the "delete implemented plans, keep unimplemented" rule) or leave them as research docs. Nothing has been moved yet.

**Keen Dreams → Commander Genius — settled by the user on 2026-11-17** ("genius for dreams, it gets dropped from Reflection").
- `reflectionhle.md` is now **Bio Menace only**: title, table row (KDreams marked dropped), data section, single `enable` options block, and Steam entry (`BIO_MENACE`, no `steamAppId`) all stripped of Keen Dreams; the old "Keen 1–5 has no port, stays DOSBox" line was removed as wrong.
- `commander-genius.md` gained a "Keen Dreams belongs to Commander Genius" section and its "settle ownership" risk is resolved. One package covers Keen 1–5 (Complete Pack [9180]) + Keen Dreams [356200].
- Rationale for the split (unchanged): Commander Genius is maintained and broad but not byte-faithful; ReflectionHLE KDreams was the faithful one but without Dreams only freeware Bio Menace is left.

**KeeperFX — Dungeon Keeper 1 only.** KeeperFX is a full rewrite of DK1 + The Deeper Dungeons; it does **not** support Dungeon Keeper 2. Data comes from the GOG Dungeon Keeper Gold install.
- **Flame resolved 2026-11-17:** `DiaLight/Flame` patches the Windows DK2 binary/payload rather than reimplementing it, so it is unpackageable — DK2 stays Wine/Proton and gets no plan.
- Mod support design: mods live in `mods/<name>/` and may override any data group (fxdata, stddata, campaigns, levels, creatures, strings, textures, sounds, music, lua); load order comes from three `keeperfx.cfg` blocks (`mods_after_base` / `mods_after_campaign` / `mods_after_map`).
- Plan exposes `games.keeperfx.mods` as an attrset, builds them with `linkFarm`, symlinks into a writable runtime dir, and writes the load order between marker comments so user cfg edits survive.
- Blocker: KeeperFX writes cfg/logs/saves next to the binary, so it cannot run from the store. Launcher syncs the store tree into `$XDG_DATA_HOME/keeperfx` first.
- Upstream CMake fetches prebuilt deps from `kfx-deps` releases into the BUILD dir.

**Stratagus / Wargus / War1gus (v3.3.2 all three).** Wargus = Warcraft II (ToD + BtDP), a Stratagus mod whose art comes out via `wartool`; War1gus = a WC1 *re-implementation* on Stratagus (`war1tool`), deliberately modernised. User owns GOG `warcraft_2_battlenet_edition` and `warcraft_orcs_and_humans`, so both get data. Wargus + Stratagus are already in pinned nixpkgs at the current version (use `pkgs.wargus`, no override); `war1gus` is absent. `stratagus` is not a top-level nixpkgs attribute (sibling file `callPackage`'d inside `wargus`), so war1gus needs either a `callPackage` of that path or our own `packages/stratagus.nix`.

**OpenJKDF2 (upstream v0.9.9).** Absent from nixpkgs; closest cousin to the existing TFE Dark Forces module. Catch: it builds with **git submodules** (vendored SDL2/OpenAL/GLEW/PhysFS) and the store-path/sha1 problem that forced those submodules to be commented out of `fetchGitTree`. Plan is to add a generic `submodules ? false` flag to `fetchGitTree` (recursive NAR hash when enabled) rather than bypassing sources.toml — see the fetchGitTree-submodules memory for the decided mechanism.

**Second batch (same day):**
- `opentyrian.md` — Tyrian 2000; OpenTyrian already in pinned nixpkgs at current upstream. (2026-11-17: `andyvand/opentyrian2000` is a *different* project, surfaced via RecompLauncher — not what this plan points at.)
- `dethrace.md` — Carmageddon Max Pack; no nixpkgs, upstream still work-in-progress but active.
- `reflectionhle.md` — after the 2026-11-17 handover, **Bio Menace only** (`BMenace`); Keen Dreams (`KDreams`) dropped to Commander Genius; Keen 1–6 were never in scope.
- `opentesarena.md` — The Elder Scrolls: Arena; upstream active but still missing saves, quests and spells, so it is not a playable replacement yet.

**Third batch (same day, user-requested after the prioritisation):**
- `openjk.md` — OpenJK, covering Jedi Academy [Steam 6020] + Jedi Outcast singleplayer [6030]. **OpenJO is not a separate project**: the JK2 SP code is `codeJK2/` inside OpenJK, and pinned nixpkgs' `openjk` (0-unstable-2026-09-29) already sets `BuildJK2SPEngine`/`BuildJK2SPGame`/`BuildJK2SPRdVanilla` true, so both games come from the one package, no `sources.*` entry and nothing new to build. Upstream grades JK2 SP "works, needs attention", so the plan lists Jedi-Academy-alone as the fallback.
  - **Updated 2026-11-17: a "Third entry: Jedi Academy: Enhanced" section was added**, because the user asked for it. JA Enhanced (`redsaurus/OpenJK`, `custom` branch) is GPL-2.0 and is *a singleplayer mod plus a patched client*, so it lands as a third option in the same module: first try layering its pk3s over `pkgs.openjk` via `fs_game`, and only write `packages/jaenhanced.nix` if the client patch turns out to be required.
- `arx-libertatis.md` — Arx Fatalis [1700]; nixpkgs 1.2.1 equals upstream, so it is a data-only job with no sources entry.
- `relive.md` — R.E.L.I.V.E. for Abe's Oddysee [15700] + Abe's Exoddus [15710]; absent from nixpkgs (upstream `AliveTeam/alive_reversing`), so it needs `sources.relive.toml`. Upstream has **no SPDX licence id** — read `LICENSE` before writing `packages/relive.nix` instead of assuming GPL. Both stores ship *Windows* builds of the Oddworld games, not the DOS originals.
- `yamagi-quake2.md` — Quake II [2320]; nixpkgs `yquake2` 8.60 is current, so no sources entry. Quake II does have singleplayer. nixpkgs splits base + `yquake2-ground-zero`/`-the-reckoning`, but the user does not own the expansions, so they stay unused.

Those third-batch plans mirror `DarkForces.nix`: LIGHT-guarded `games.<x>.enable`, a `programs.steam.games.<KEY>` entry, no `home.packages` entry, and a wrapper that redirects writable state into HOME.

**Fourth batch (same day): `sonic-mania.md`.** `RSDKModding/Sonic-Mania-Decompilation`, `v1.1.1` (released 2025-11-01, repo pushed 2026-11-13, 835 stars). Needs **git submodules**, so it is blocked on the same recursive-hash `fetchGitTree` fix as dethrace/OpenJKDF2. It has a built-in mod loader (`RETRO_MOD_LOADER=on` by default, mods are `mods/<name>/` with a `mod.json`), so the repo gets mod support for free — the plan exposes `games.sonicmania.mods` as an attrset fed into a `linkFarm`. GitHub reports licence `NOASSERTION`, so read `LICENSE` before deciding whether the derivation is local-use only. Game data is just `Data.rsdk` from Steam app `584400`.

**Fifth: `openmw.md` (same day).** Morrowind via nixpkgs `openmw` 0.51.0 (= upstream stable, so no sources override), with the design the user approved: `games.openmw.mods` as an **ordered list** of `{ name, src, plugins ? null }`, build-time `openmw.cfg` (`data=` / `fallback-archive=` / `content=`), `plugins = null` auto-detecting and sorting `.esm`/`.esp`. Details in the OpenMW design memory.

**Sixth: `fallout-ce.md` (2026-11-17, user-requested).** Fallout 1 CE + Fallout 2 CE as **two separate ports**, with a comment noting Et Tu is a future want.
- `fallout2-ce` is **already in nixpkgs at 1.3.0 = upstream latest**, and nixpkgs' own launcher already `cd`s into `$XDG_DATA_HOME/fallout2-ce` and checks for `master.dat`/`critter.dat` — so that half is a data-only job, no sources entry.
- `fallout1-ce` (`alexbatalov/fallout1-ce`, tags v1.0.0/v1.1.0) is **absent from nixpkgs** and only ~60% done; it needs its own derivation (licence `sustainableUse`).
- Both upstreams report licence `NOASSERTION`; neither repo is archived (pushes 2025-01/2025-02).
- Module is shaped so the Et Tu swap later is a data change only; do not promise Et Tu support (see the fallout-ce reference memory).

**Seventh: `openq4.md` (2026-11-17, user-requested "all singleplayer Quake games").** openQ4 v0.14.1 (v0.14.0 was withdrawn as broken), absent from nixpkgs. Runs two campaigns — the original Quake 4 campaign and *The Awakening* — on its own game code with its own saves. `+set fs_basepath` against a writable runtime dir; Steam entry replacing app 2210. Singleplayer Quake coverage is then complete: Quake II [2320] via `yamagi-quake2.md`, Quake 4 [2210] via `openq4.md`; Quake 1 and Quake III aren't owned (and Quake III is MP-only).

**Eighth: `commander-genius.md` (2026-11-17, user-requested).** Commander Genius for Commander Keen Complete Pack [9180] (Keen 1–5) and Keen Dreams [356200]; Cosmo isn't owned. Main repo is GitLab `Dringgstein/Commander-Genius` (GitHub `gerstrong/Commander-Genius` is a 3.6.4 mirror); absent from nixpkgs. Build trap: its CMake `FetchContent`s SDL2/SDL2_image/SDL2_mixer/SDL2_ttf/curl for static builds, so the package must hand it system libraries or it hits the network. CMake ≥ 3.29.

**Ninth: `pokemon-infinite-fusion.md` (2026-11-17, user-requested, wanting the Pokémon images pre-fetched so they can go through size optimization).**
- **mkxp-z is a hard prerequisite.** PIF is RPG Maker XP + Pokémon Essentials (e18) and the PortMaster/Steam-Deck guidance says it needs mkxp-z on Linux, so `packages/mkxp-z.nix` must land first (it also unlocks the 12–14 owned RPG Maker titles from the runtime survey). Wine with the bundled `Game.exe` is the documented fallback only.
- **Two separate fetch units** because they move on different schedules: the game payload (official installer, unpacked via `innoextract`/7z) and the **monthly community sprite packs**, one `sources.pif.toml` `[zip]` entry per pack so packs can be added selectively.
- **Sprites are not in the base game**: they are community packs dropped into `Graphics/CustomBattlers/`, and the `<head>.<body>.png` naming plus `Sprites/` subdirectory is load-bearing — a pipeline that flattens paths breaks sprite lookup silently.
- **Size optimization reuses `lib/optimize`** (the existing `oxipng -o<level> --strip all --alpha` chain plus `optipng`/`advpng`); a `pif-sprites-optimized` derivation runs the whole tree through it and that is what gets linked in. `pngquant` stays opt-in because these are pixel-art sheets and lossy quantization bands badly.
- **Risks:** Nintendo IP (free fan game, personal use, not redistributable), and sprite packs are distributed as **Discord attachments whose URLs expire**, so those source entries need re-pinning rather than "set and forget".
- **Flagged, not solved:** the game has an in-game sprite downloader that reaches the network at runtime, so the module must point it at the local optimized dir or disable it, otherwise it can fetch unoptimized sprites over the store tree.

**Tenth: `cosmo-cosmic-adventure.md` (2026-11-17, user-requested).** Cosmo's Cosmic Adventure runs on Commander Genius, so it gets **no engine of its own** — the plan extends the approved `commander-genius.md` module instead of standing alone.
- New `cosmo.enable` option feeding the same single `$XDG_DATA_HOME/commander-genius` runtime dir as Keen.
- Cosmo's three freeware episodes come from `sources.commander-genius.toml` as one `[zip] cosmo.episodes` entry.
- A `COSMO` `programs.steam.games` entry with **no `steamAppId`** (extra shortcut, not a replacement).
- Main flagged risk: Commander Genius identifies games by **episode directory name**, so the data tree must be shaped to its detection rules rather than guessed — verify the expected dir names before wiring the link farm.

**Eleventh (2026-11-17, after the five-title survey): `drl.md`, `srb2.md`, `solarus-zsdx.md`.**
- `drl.md` — `ChaosForge/doomrl` 0.10.0, source *and* free assets. Toolchain confirmed present in the pinned nixpkgs `all-packages.nix`: `pkgs.fpc` and `pkgs.lazarus` (Lazarus lives in `development/compilers/fpc/lazarus.nix`); `fpcvalkyrie` 0.10.0 pinned separately via sources. Build with `lazbuild`. Trap recorded in the plan: **Lua 5.1 is loaded by name** (no `lua5_1` in by-name), so 5.4 will not do. Needs a runtime dir because it writes saves next to itself.
- `srb2.md` — `pkgs.srb2` 2.2.15 already equals upstream, so no override at all: purely `games.srb2.mods` → `linkFarm` with `-home`/`-file` wiring. Mods are WAD/PK3/Lua, version-coupled to 2.2.x.
- `solarus-zsdx.md` — `pkgs.solarus` 2.1.4 with free quest data; the whole risk is engine/quest version pairing, so task 1 is to read the quest's declared engine version and only override Solarus if it wants newer. Savegames live *inside* the quest dir, hence the writable runtime copy.

**Why:** these were user-requested follow-ups to the engine prioritisation; the designs contain decisions (DK1-only scope, mods attrset shape, submodule handling, JK2-SP fallback, JAE pk3-over-nixpkgs-first, Keen Dreams assignment, mkxp-z-before-PIF, sprite-pack layout/optimization, Cosmo-as-a-Commander-Genius-option, data-only SRB2/Solarus/arx/yquake2) that shouldn't be re-derived.
**How to apply:** if asked to implement any of these, read the corresponding plan file first; remember DK2 is out of scope entirely (no packageable engine), that `fetchGitTree` still needs its submodule path before OpenJKDF2 or Sonic Mania can build, that OpenTESArena is not yet feature-complete enough to replace DOSBox, that OpenJK needs no separate JK2 build, that Fallout 2 CE is data-only because nixpkgs already has it, that **Keen Dreams belongs to Commander Genius** (ReflectionHLE = Bio Menace only), that Pokémon Infinite Fusion cannot be packaged before mkxp-z, and that **Cosmo is not a separate engine package** — it is an option inside Commander Genius.
