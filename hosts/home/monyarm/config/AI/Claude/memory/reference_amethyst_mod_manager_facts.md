---
name: reference_amethyst_mod_manager_facts
description: "Verified 2026-11-17 from the user's own install: scheme registrations, config layout and per-game paths.json fields, deploy modes, the six games with real data, the Nexus slugs for those six and where to find them (nxm.log, custom_games nexus_game_domain), plus Nix packaging reference repos"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-17T01:38:26.820Z
---

Verified 2026-11-17 against the user's install on monyarm@monyarm (Amethyst was set up there, not on this host):

- Registers five URL handlers itself: `nxm`, `ror2mm`, `gale`, `modl`, `wabbajack` (`amethystmodmanager-gale.desktop`, `-modl.desktop`, `-nxm.desktop`, …), all `Exec=/mnt/mediaSSD/Games/Amethyst.AppImage --<flag> %u`. It only understands its own game set, so ids it doesn't know die silently. On the host, `xdg-mime query default x-scheme-handler/nxm` returns `amethystmodmanager-nxm.desktop` — but the repo's own generated script is what should own `nxm://`.
- Config: `~/.config/AmethystModManager` (`amethyst.ini`, `custom_games/`, `handler_store/` with `repositories.json` + `definitions/builtin/`); data under `~/.local/share/AmethystModManager`. `amethyst.ini` holds `[paths]` (`default_staging_path`, download cache), `[nexus] last_known_premium`, window geometry.
- Games are **display-name directories** under `~/.config/AmethystModManager/games/`, each with `paths.json` carrying `game_path`, `prefix_path`, `deploy_mode`, `staging_path`, `shortcut_appid`, plus `game_settings.json`, `deploy_state.json`, `fomod_selections`, `bain_selections`; some have `wine_dll_overrides.json`.
- It ships ~127 game dirs (full Thunderstore/manager game catalog) but only these have real config/data: **Cyberpunk 2077, Oblivion, Stardew Valley, Kotamon, Dressmaker, GTA Vice City - LC Engine**. Examples: Kotamon = Steam 4294490 with `prefix_path=…/compatdata/4294490/pfx`; Oblivion/Cyberpunk/Stardew/GTA VC-LC deploy by **symlink** from `…/Amethyst/<Game>/profiles/default`.
- **Do not treat `games/` or the builtin definitions as the full game list**: there are 52 builtin definitions and 51 hand-added `custom_games/*.json` (schema: `name`, `game_id`, `exe_name`, `deploy_type`, `nexus_game_domain`, …). Titles added by hand are defined at add time and never show up in `handler_store/definitions/builtin/` — the user pushed back hard on hunting only Amethyst's own definitions.
- Do **not** classify those games as "not Nexus games": they are simply titles Amethyst manages internally, whether via Nexus, a Thunderstore-ish source, or a Windows title under Proton — so a single `amethyst` manager entry covers all of them.
- **Nexus slugs for the six handled games** (no need to re-derive): Cyberpunk 2077 → `cyberpunk2077`, Oblivion → `oblivion`, Stardew Valley → `stardewvalley`, Dressmaker → `dressmaker`, Kotamon → `kotamon`, GTA Vice City - LC Engine → `grandtheftautovicecity`. Sources: `~/.local/share/AmethystModManager/logs/nxm.log` (every opened link; hits 1266/12/15/51 for the first four) and `custom_games/<id>.json`'s `nexus_game_domain` for the two hand-added ones that never appear in the log.
- Link shapes seen in the log: `nxm://<slug>/mods/<mod>/files/<file>?key=…&expires=…&user_id=…` and `nxm://<slug>/collections/<id>/revisions/<n>`; the first path segment is the game key.
- Packaging references: `a4blue/Amethyst-Mod-Manager-Nix-Packaging` and `Briaoeuidhtns/amethyst-nix` (crib a derivation rather than inventing one).
- r2modman: official distribution is the `r2modman-3.2.21.AppImage`; it is Electron, so wrap it (`appimageTools.wrapType2`) and do not rebuild it against nixpkgs' electron. `Zard-Studios/r2modmac` is an unrelated separate Rust Thunderstore manager.
