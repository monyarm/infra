# Daggerfall Unity

## Context

Adding Daggerfall Unity (open-source *Elder Scrolls II: Daggerfall* engine reimplementation) to `hosts/home/monyarm/games/`, with real config generation and mod handling — not just a `home.packages` add. Several things needed checking before design could land, all now resolved:

- **Engine source**: checked nixpkgs' `daggerfall-unity` commit history and upstream releases directly. nixpkgs has been pinned at v1.1.1 since Oct 2024, but upstream's only newer tag since then (`v1.1.1-cve-2025`, Oct 2025) ships a **byte-identical Linux binary** (the CVE fix only touched the Windows DLL) — nixpkgs isn't actually stale for Linux. Also, nixpkgs' derivation isn't a from-source build (`fetchzip` of a prebuilt GitHub Release asset — no Linux from-source recipe exists upstream), so this repo's `sources.toml`/`fetchGitTree` pinning pattern doesn't apply — nothing buildable to pin. **Decision: `pkgs.daggerfall-unity` (not `-unfree`) as-is, no override.**
- **Game data**: Bethesda's original 2009 freeware hosting is dead (404/500/403, confirmed live). Best current source: Steam appId `1812390` (confirmed free), which Daggerfall Unity's own GitHub wiki documents as officially working "out of the box." Uses this repo's existing `fetchSteam` (`lib/fetchers/steam.nix`) — the dominant fetcher pattern for exactly this shape (`Doom/wad/doom_i_ii.nix`). A `fetchGDrive` fallback exists too (the DFU wiki's alternate `DaggerfallGameFiles.zip`) but Steam is primary.
- **Mod/settings architecture**: read Daggerfall Unity's actual source (`ModManager.cs`, `Mod.cs`, `ModSettingsData.cs`) directly, not just docs. This resolved the mod-directory-merging question and the per-mod-settings question precisely — see Architecture below.

Package inspection this session (`nix build nixpkgs#daggerfall-unity`, `strings` on `Assembly-CSharp.dll`, and direct GitHub source reads) confirmed every concrete path/filename used throughout this plan.

## Architecture

**Directory**: `hosts/home/monyarm/games/Bethesda/DaggerfallUnity/`, auto-imported via the existing `autoImport ./games`. **`git add` new files immediately** (untracked `.nix` files are invisible to `builtins.getFlake`).

```
Bethesda/
├── default.nix                      # imports = [ ./DaggerfallUnity ];
└── DaggerfallUnity/
    ├── default.nix                  # option schema, mkModDir-based mods dir, launch wrapper,
    │                                 # programs.steam.games entry
    ├── data.nix                     # fetchSteam appId 1812390 -> raw game-data derivation
    └── mods/
        ├── default.nix               # autoImport ./., registers games.bethesda.daggerfallUnity.mods.<name>
        └── (empty for this pass — infrastructure only, no mods seeded yet)
```

### `mkModDir` — building it for real, per `GAME_IDEAS.md`'s own spec

`GAME_IDEAS.md`'s "Shared nix helpers (proposed, not designed yet)" section already scoped this: *"takes a game dir derivation plus an attrset shaped like `{ "path/inside/mod/dir" = drv-or-list-of-drvs; ... }`, and produces the merged mod-directory tree."* Build it for real now, as DFU's first consumer, rather than an inline one-off — it directly covers Ikemen's `chars/<name>/` and SuperTuxKart's `addons/{karts,tracks}/` from the same doc when those get built later.

**Location**: new `lib/modDir.nix`, wired into the `lib/default.nix` aggregation the same way `scummvmOptimize`/`compressRom` already are (each a sibling `import ./<file>.nix {...}`, merged into the `all`/`customLib` attrset — confirmed by reading `lib/default.nix` directly).

**Signature**: `mkModDir :: package -> attrsOf (listOf package) -> package`

**Mechanics** (validated against `symlinkJoin`'s real `lndir`-based behavior — confirmed via live package inspection that `StreamingAssets/Mods` is a real directory node, not a symlink, so this is safe): `pkgs.symlinkJoin` over the base game derivation, with a `postBuild` hook that, for each `path -> [ drvs ]` entry in the attrset: `rm -rf $out/<path>` (safe — operating on a directory `symlinkJoin`'s own build materialized, not mutating the immutable input), recreate it, then symlink each list item into it named by that derivation's own `.name` (handles both single-file mods, like DFU's `.dfmod`s, and whole-directory mods, like a future Ikemen `chars/<name>/`, uniformly). Derivation names are intentionally the destination names; validate destination paths as safe relative paths, quote shell expansions, and reject collisions.

**DFU's use**: `mkModDir daggerfall-unity { "DaggerfallUnity_Data/StreamingAssets/Mods" = mapAttrsToList (n: m: m.package) mods; }`.

Must carry forward `meta.mainProgram = "DaggerfallUnity.x86_64";` explicitly (confirmed via `nixpkgs#daggerfall-unity.meta.mainProgram`) — without it, `Steam/shortcuts.vdf.nix`'s `resolveExe` falls back to the wrapper derivation's own name, pointing shortcuts at a nonexistent binary.

### Mod/load-order registration (`options.games.bethesda.daggerfallUnity`)

Per your split — registration and ordering are separate concerns:

```nix
mods = mkOption {
  type = attrsOf (either package (submodule {
    options = {
      package = mkOption { type = package; };
      settings = mkOption { type = nullOr (attrsOf (attrsOf str)); default = null; };
      guid = mkOption { type = nullOr str; default = null; };  # required iff settings != null
      enabled = mkOption { type = bool; default = true; };
    };
  }));
  default = { };
};
loadOrder = mkOption {
  type = listOf str;  # names referencing keys in `mods`; defines Mods.json priority order
  default = [ ];
};
```

Bare-package entries get normalized to `{ package = drv; settings = null; guid = null; enabled = true; }` via a `mapAttrs` in `default.nix`, so every downstream consumer (mkModDir input, Mods.json generator, per-mod-settings generator) deals with one uniform shape. `mods/*.nix` files (via `autoImport`) each contribute one entry — same "one file per source" shape as `Doom/wad/*.nix` — empty for this pass, per your decision to verify base infrastructure before adding real mods.

### Runtime state — source-verified, not guessed

Read `ModManager.cs`/`Mod.cs`/`ModSettingsData.cs` directly (not just wiki/forum posts) to nail down exactly what's read/written where:

- **`StreamingAssets/Mods/<name>.dfmod`** — the mod binaries themselves, inside the Nix-store-based engine package. Read-only is correct; DFU only reads these (`AssetBundle.LoadFromFile`), never writes here in current versions. `mkModDir` fully covers this — it's the one piece of runtime state that genuinely needs a store-immutability workaround.
- **`ModDataDirectory` = `PersistentDataPath/Mods/GameData/`** (`ModManager.cs:102-105`) — on Linux, `PersistentDataPath` resolves via Unity's standard convention to `~/.config/unity3d/Daggerfall Workshop/Daggerfall Unity/` (company/product strings confirmed from the built package's `app.info`). **This is a normal, already-writable home-directory tree, unrelated to the Nix-store-based `StreamingAssets`** — so it's handled with home-manager's own file-writing mechanisms, the same way this repo already handles `shortcuts.vdf`/`localconfig.vdf` (both under `~/.local/share/Steam/...`, a directly analogous "home-manager-writable path that an external app also actively rewrites" situation), not a launch wrapper. Three files live here, all managed via `home.activation` (`lib.hm.dag.entryAfter [ "writeBoundary" ]`, run at `home-manager switch` time — not `xdg.configFile`/`home.file`, which would symlink into the read-only store and break DFU's own runtime writes to these same files):
  - **`settings.ini`** — DFU's main settings file (video/audio/controls/`MyDaggerfallPath`), which DFU itself rewrites whenever the user changes a setting in-game. Modeled directly on `Steam/shortcuts.vdf.nix`'s existing `localconfigPatcherScript`, using Python's stdlib `configparser`. The activation script reads `settings.ini` if present (falling back to DFU's own shipped `defaults.ini` template otherwise), patches only `MyDaggerfallPath` under `[Daggerfall]` to point at the `data.nix` fetch output, and rewrites the INI. Byte-for-byte preservation is not required; preserving the settings semantically is sufficient.
  - **`Mods.json`** (`ModManager.cs:800-860`, `WriteModSettings`/`LoadModSettings`) — the master enabled/load-order list. Fully Nix-owned, regenerated every `home-manager switch` from `mods` + `loadOrder` (list order = priority) — same full-overwrite treatment as `shortcuts.vdf` itself, since this is purely Nix-derived declarative content. Generate DFU's actual serialized `Mod` records, including `FileName`, `Enabled`, and `LoadPriority`, rather than a simplified structure. Do not create an empty `Mods.json`: upstream skips writing it when there are no discovered mods.
  - **`<ModGUID>/modsettings.json`** (`ModSettingsData.cs:47-50`, `Mod.cs:123-126`, keyed by the mod's GUID, not filename) — per-mod, per-user **values**. The activation pass writes this only when `settings != null`, using DFU's `SettingsValues` shape: `{ "SettingsVersion": "...", "Values": { "SectionName": { "KeyName": "serialized value" } } }`. Values are strings, including booleans and numbers. Require `guid` whenever `settings != null`; the GUID must be looked up out of band because it is embedded in the mod bundle. The declared settings option should represent this nested section/key value structure rather than an arbitrary attrset. The schema/defaults ship embedded *inside* the `.dfmod` AssetBundle as a `TextAsset`; no separate schema file is fetched.
  - For mods **without** declared `settings` ("just a package") — the activation script does nothing for that mod's `ModDataDirectory` subtree. Confirmed this needs no special handling at all: `ModDataDirectory` was never inside the read-only `StreamingAssets` tree, so DFU creates `<guid>/modsettings.json` itself the first time the mod's in-game settings panel is touched, same as a normal install. The `LegacySettingsPath` fallback (`StreamingAssets/Mods/<file>.json`, from older DFU versions) only matters for migrating a pre-existing legacy file — irrelevant for a fresh Nix-managed install, since that file will never exist.

Target paths (same Unity persistent-data convention, confirmed via `app.info` strings): `~/.config/unity3d/Daggerfall Workshop/Daggerfall Unity/settings.ini` and `.../Mods/GameData/{Mods.json,<guid>/modsettings.json}` — high confidence, not yet runtime-observed; verify with one real launch (see Verification).

### Steam shortcut

`programs.steam.games.daggerfallUnity` in `Bethesda/DaggerfallUnity/default.nix`, per your decision — DFU's first `programs.steam.games` entry that's a native package with no separate launcher (`launcher = null`, falls through to `resolveExe config.game`). Points directly at the `mkModDir`-wrapped package (the only wrapping layer needed now — no `makeWrapper`/launch-wrapper layer) — depends on `meta.mainProgram = "DaggerfallUnity.x86_64";` being carried through that layer correctly.

## Sequencing

1. **Probe and fixtures**: capture or source-verify the exact DFU `Mods.json` and `SettingsValues` formats, record the Unity persistent-data paths, and perform the one-time Steam depot/manifest lookup for appId 1812390.
1. **`lib/modDir.nix`**: implement `mkModDir` generically (not DFU-specific), wire into `lib/default.nix`, and test empty mods, files, directories, nested paths, invalid paths, and name collisions. Derivation `.name` remains the intended destination filename.
1. **Base data**: add `data.nix`, verify the credential-dependent Steam fetch and confirm the fetched tree shape matches `.../DF/DAGGER` before wiring further.
1. **Engine + empty mods dir**: add the option schema and `mkModDir` call with `mods = { }` (empty). Build in isolation and confirm the package layout and executable still work.
1. **Pure state generators**: implement the `configparser` INI patch and the exact `Mods.json`/`SettingsValues` generators. Assert `settings != null -> guid != null`, assert all `loadOrder` names exist and are unique, and do not generate `Mods.json` for an empty mod set. Add fixture tests before activation.
1. **Activation**: write the generated state under `~/.config/unity3d/...` using `$DRY_RUN_CMD`, parent-directory creation, and atomic temp-file-plus-rename writes. Define malformed-file and stale per-mod GUID-directory behavior. Runtime `home-manager switch`/launch checks are manual operator tests, not routine flake verification.
1. **First real mod**: add one `mods/*.nix` entry via `fetchNexus` + `getFile`, confirm it appears in `StreamingAssets/Mods/` and DFU's in-game list picks it up. If it declares settings, supply its real GUID and verify the seeded values in-game.
1. **`programs.steam.games` entry**: add last, once the `mkModDir`-wrapped package launches standalone with correct `meta.mainProgram`. Keep the Daggerfall data app ID distinct from the synthetic DFU shortcut.
1. **`git add`** the new `Bethesda/` tree and `lib/modDir.nix` as soon as they exist so flake evaluation sees them.

## Verification

- Build the `mkModDir`-wrapped package standalone, launch it, confirm it reaches DFU's main menu with no first-run data-path prompt (proves `MyDaggerfallPath` patching worked).
- Confirm in-game "Mods" list shows zero errors against an empty mod set.
- Manually change an in-game video setting, run `home-manager switch` again, relaunch, confirm the setting survived semantically (proves the `settings.ini` activation patcher isn't clobbering unrelated settings).
- Confirm repeated activation is idempotent, dry-run performs no writes, and interrupted writes leave the previous state file intact.
- Once a real mod is added: confirm it loads, and if it has declared `settings`, confirm the seeded values actually appear correctly in its in-game settings panel.
- Confirm the Steam library/Big Picture shows the synthetic shortcut and launches the same wrapped binary, not a broken path or the original data app.
