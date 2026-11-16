---
name: project-pending-engine-plans
description: Engine integration plans for TFE/Dark Forces, TRX/Tomb Raider I-III, OXCE/X-COM (finalised 2026-11-13) with resolved CLI/data-path gotchas; all three were implemented later on 2026-11-13 and build
metadata:
  type: project
  origin: opencode
  modified: 2026-11-13T21:29:28.950Z
---

Game engine integrations planned 2026-11-13 (plans were in `.claude/plans/{dark-forces-tfe,tomb-raider-trx,xcom-oxce}.md`, deleted 2026-11-14 after implementation) and implemented the same day: `packages/theforceengine` override + `packages/tombraider-trx.nix` + `packages/openxcom-extended.nix`, with modules under `hosts/home/monyarm/games/{DarkForces,TRX,OpenXcom}`; all three packages and the per-campaign TRX data trees built successfully. Verify current state in the tree rather than trusting these notes.

- Star Wars Dark Forces — The Force Engine: reuse `pkgs.theforceengine`, override `src` from `sources.tools.theforceengine` + `version` only. Entry is `[git-tag]` (newest tag `v.1.30.000`, 2026-11-03). TFE has no CLI flag or env var for data, so the wrapper seeds/repairs `[Dark_Forces] sourcePath` in `settings.ini` while leaving other sections intact. `ENABLE_OGV_CUTSCENES` is dead weight (only guards the remaster path; classic LFD path compiles either way) — no libtheora/ogg/vorbis, no cmakeFlags. Remaster assets dropped (user does not own Steam 2292260).
- Tomb Raider I-III — TRX: package as `packages/tombraider-trx.nix` (`pkgs.trx` is an unrelated nixpkgs RTP tool). Manifest is `sources.trx.toml` holding engine + art zips (`./update-sources.py trx`). Engine is `[git-tag]` with no `#tag` fragment (fetcher tracks newest tag; newest on 2026-11-13 was `trx-1.12`). TR1 depot is a GOG DOSBox repack with a 2352-byte-sector ISO needing sector strip + 7z; TR1 music `02..10.mp3` → `track02..10.mp3`; TR2/TR3 need no transcode.
  - Campaign selection: `--mod tr1|tr2|tr3` (`tr1-ub`, `tr1-demo-pc`, … pick other mods). `-g`/`--gold` is the legacy expansion switch. TRX remembers the last game, so every wrapper/shortcut must pass `--mod`.
  - Meson: `staticdeps` defaults true → pass `-Dstaticdeps=false`; Lua uses `-Dlua_dep=lua5.4` when plain `lua` is absent; uthash is `check_header`, so it goes in `buildInputs`.
  - `cfg/ games/ modules/ scripts/` ship in git at `data/trx/ship/`; the wrapper sets `TRX_DIR` to a writable XDG dir whose read-only parts link back to the store (engine writes `shell.json5`, console history next to `cfg/`).
  - Art zips are mandatory (gameflow names `title.webp`, loading screens, etc.; missing art aborts gameflow load). Unversioned URLs `https://lostartefacts.dev/aux/trx/tr{1,2,3}.zip` — no versioned paths exist. Sibling zips for unowned expansions/TR4 stay unused.
  - Copying the store-derived tree with `cp -r` leaves read-only dirs, so `chmod -R u+w` before layering art zips into `$out/share/trx/games/`.
- X-COM UFO Defense — OXCE: no nixpkgs package (`pkgs.openxcom` is the legacy engine). `[git] tools.openxcomExtended` (branch `oxce-plus`), deps sdl12-compat + SDL_gfx/image/mixer + zlib, RapidYAML vendored. No OXCE mods — the user does not want them. `bin/common/` (Language, Palettes, Resources, Shaders, SoldierName) must be installed as engine data or the game won't start; `bin/standard/` skipped. `-data` is a root with `common/` and `UFO/` as siblings, not a bare `UFO/`.

Still open: TR4 (upstream), UB/GM/LA expansions (unowned), TRX level-pack mods (deferred), and whether TRX's runtime actually resolves all art paths on a real launch (build success does not prove that).

**Why:** User tracks these as next game-support work and reviews plans before implementation; they care about game-improving mods only for titles where they asked for them.

**How to apply:** Read the plan file and check the tree before starting or revisiting any of the three. Mods: TRX = level packs only (deferred); TFE = thin, defer; OXCE = none.
