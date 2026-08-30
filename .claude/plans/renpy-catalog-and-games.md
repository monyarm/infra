# Ren'Py Catalog And Games Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reproducible Ren'Py game catalog workflow, use it to find owned titles, and package a small set of verified non-adult Ren'Py games with a shared runtime.

**Architecture:** Resolve the external catalog during the existing source-update workflow, never during Nix evaluation or builds. Normalize catalog records to Steam AppIDs/GOG slugs, intersect them with `games.list`, and manually verify only the resulting candidates. Package title data separately from the shared `pkgs.renpyMinimal` runtime, preserving each game's complete `game/` directory and redirecting mutable state to writable XDG paths.

**Tech Stack:** Python, `sources.toml`/`update-sources.py`, Nix/Home Manager, `pkgs.renpyMinimal`, existing `fetchSteam`/`fetchGOG`/itch fetchers, Steam shortcut registration.

**Spec:** `GAME_IDEAS.md`, especially the Ren'Py shared-runtime and Katawa Shoujo sections.

## Global Constraints

- HTTP, JSON, archive inspection, and source expansion happen in `update-sources.py`, not Nix evaluation or builds.
- Generated source metadata contains static URLs and hashes; Nix must not query VNDB, Steam, or other APIs.
- Use `pkgs.renpyMinimal` for packaged games; do not retain bundled engine binaries unless a title-specific compatibility test proves they are required.
- Launch Ren'Py with the project root containing `game/`, not with the `game/` directory itself.
- Preserve the complete `game/` tree initially, including `.rpy`, `.rpyc`, `.rpa`, `tl/`, media, and metadata files.
- Redirect saves, persistent data, logs, cache, and generated scripts away from the read-only Nix store.
- New `.nix` files must be staged before flake evaluation can see them.
- Do not activate Home Manager or NixOS while verifying this work.
- Adult/pornographic candidates are deliberately excluded from the initial game registry; Sakura titles are included.

## Candidate Scope

The catalog intersection produced these strong initial candidates. IDs are from `/home/monyarm/.nix/games.list`.

### External first-title proof

- **Katawa Shoujo**: freeware, not present in `games.list`; existing save-data plumbing is at `hosts/home/monyarm/games/RenPy/.renpy/katawashoujo_actual_1.3/`.

### Owned GOG candidates

- **Our Life: Beginnings & Always**: `our_life_beginnings_always`.
- **Sunrider: Mask of Arcadius**: `sunrider_mask_of_arcadius`.

### Owned Steam candidates

- **Sakura Spirit**: `313740`
- **Sakura Angels**: `342380`
- **Sakura Fantasy Chapter 1**: `375200`
- **Sakura Beach**: `377680`
- **Sakura Swim Club**: `402180`
- **Sakura Beach 2**: `407980`
- **Sakura Dungeon**: `407330`
- **Sakura Shrine Girls**: `517000`
- **Sakura Space**: `521500`
- **Sakura Nova**: `539670`
- **Sakura Agent**: `575510`
- **Sakura Magical Girls**: `581520`.
- **Sakura Gamer**: `685680`
- **Sakura Cupid**: `733740`
- **Sakura Sadist**: `813700`
- **Sakura MMO**: `935070`
- **Sakura MMO 2**: `968950`
- **Sakura MMO 3**: `1064130`
- **Sakura Gamer 2**: `1161650`
- **Sakura Fox Adventure**: `1157640`
- **BAD END THEATER**: `1764390`

Do not add every candidate at once. Katawa Shoujo is the first runtime proof, followed by one Steam title and one GOG title. The remaining candidates become data entries only after their exact depot/archive layout and shared-runtime compatibility are verified.

## Catalog Sources And Evidence

Use the following source order:

1. **VNDB API v2**: `https://api.vndb.org/kana`
   - Primary Ren'Py-specific source for visual novels.
   - Query release records by engine `Ren'Py` and retain VNDB release IDs, titles, engine, freeware status, external links, and release metadata.
1. **PCGamingWiki Cargo/API**: `https://www.pcgamingwiki.com/wiki/PCGamingWiki:API`
   - Independent engine evidence and Steam/GOG identifier resolution.
1. **IGDB**: `https://api-docs.igdb.com/`
   - Supplemental engine and external-store mapping; requires credentials and should not be mandatory for the first pass.
1. **Ren'Py game directory**: `https://games.renpy.org/`
   - Supplemental first-party discovery source when its catalog is available.
1. Steam metadata, Lutris, and GitHub lists
   - Discovery and identifier-resolution sources only; Steam genre tags are not engine evidence.

Normalize each record to this shape before intersection:

```json
{
  "source": "vndb",
  "source_id": "r123456",
  "title": "Example",
  "engine": "Ren'Py",
  "engine_evidence": ["vndb:release.engine"],
  "steam_appid": "123456",
  "gog_id": "example",
  "vndb_id": "v123456",
  "urls": [],
  "confidence": "high",
  "retrieved_at": "YYYY-MM-DD"
}
```

Match against `games.list` in this order: Steam AppID, GOG slug/product ID, canonical store URL, then reviewed title aliases. Keep uncertain matches separate from confirmed matches. Engine labels from genre tags, descriptions, or title names alone are insufficient.

## File Map

- Create: `scripts/renpy-catalog.py` for update-time API retrieval, normalization, intersection, and report generation.
- Modify: `update-sources.py` to add an explicit Ren'Py catalog source operation without changing generic URL processing.
- Modify: `sources.toml` with the catalog source definition and later pinned game sources.
- Create: generated reviewed catalog data under the existing source-metadata location selected by `update-sources.py`; do not hand-maintain generated URLs or hashes.
- Modify: `hosts/home/monyarm/games/RenPy/default.nix` to expose runtime/game options while preserving the existing `.renpy` out-of-store state link.
- Create: `hosts/home/monyarm/games/RenPy/mkGame.nix` for a minimal project-root derivation and launcher wrapper.
- Create: `hosts/home/monyarm/games/RenPy/games/katawa-shoujo.nix` for the first concrete title.
- Create: `hosts/home/monyarm/games/RenPy/games/steam.nix` for verified Steam candidates.
- Create: `hosts/home/monyarm/games/RenPy/games/gog.nix` for verified GOG candidates.
- Create: `hosts/home/monyarm/games/RenPy/tests/` or the repository's established test location for catalog and project-layout fixtures.

## Implementation Tasks

### Task 1: Build The Catalog Intersection

**Files:**

- Create: `scripts/renpy-catalog.py`
- Modify: `update-sources.py`
- Modify: `sources.toml`
- Test: catalog parser fixtures in the repository's existing Python test location

**Interfaces:**

- `load_games_list(path) -> list[OwnedGame]`

- `normalize_catalog_record(record) -> CatalogRecord`

- `intersect_catalog(records, owned_games) -> {"confirmed": [...], "uncertain": [...]}`

- `write_catalog_report(result, output_path) -> None`

- [ ] Add fixture tests for Steam AppID matching, GOG slug matching, duplicate titles across providers, and alias matching.

- [ ] Add fixture tests proving visual-novel genre metadata without an explicit Ren'Py engine record remains uncertain.

- [ ] Implement VNDB retrieval using a bounded query for Ren'Py releases and record retrieval date, query parameters, and response hash.

- [ ] Add PCGamingWiki and IGDB as optional corroboration inputs; a failed supplemental source must not erase the primary VNDB result.

- [ ] Parse the local `games.list` provider sections without treating display titles as stable IDs.

- [ ] Emit confirmed and uncertain reports with source evidence and platform metadata.

- [ ] Add the explicit update-sources dispatch and ensure no network/API call occurs during Nix evaluation or derivation builds.

- [ ] Run the parser against the current `games.list` and review the diff, excluding adult titles from the package candidate output.

### Task 2: Prove The Shared Ren'Py Runtime With Katawa Shoujo

**Files:**

- Modify: `hosts/home/monyarm/games/RenPy/default.nix`
- Create: `hosts/home/monyarm/games/RenPy/mkGame.nix`
- Create: `hosts/home/monyarm/games/RenPy/games/katawa-shoujo.nix`
- Test: project-root and launcher fixtures

**Interfaces:**

- `mkRenPyGame { name, gameData, renpy ? pkgs.renpyMinimal, saveDirName, ... } -> package`

- `games.renpy.games.<name>` registry entries

- `programs.steam.games.<name>` shortcut entries

- [ ] Confirm a stable legitimate Katawa Shoujo archive source and pin its URL/hash through the existing source-update workflow.

- [ ] Extract only after inspecting the archive; install the complete `game/` directory under `$out/share/games/katawa-shoujo/game/`.

- [ ] Generate a wrapper equivalent to:

```sh
exec ${pkgs.renpyMinimal}/bin/renpy \
  --savedir "${XDG_DATA_HOME:-$HOME/.local/share}/renpy/katawa-shoujo" \
  "$out/share/games/katawa-shoujo" run "$@"
```

- [ ] Verify the wrapper passes the project root and never attempts to write into `$out`.
- [ ] Preserve the existing `.renpy` out-of-store symlink and confirm Katawa Shoujo persistent data remains writable.
- [ ] Add the Steam shortcut only after the standalone wrapper launches.
- [ ] Confirm a new game, save, load, audio, and persistent data behavior manually.

### Task 3: Add One Steam And One GOG Proof Candidate

**Files:**

- Create: `hosts/home/monyarm/games/RenPy/games/steam.nix`
- Create: `hosts/home/monyarm/games/RenPy/games/gog.nix`
- Modify: `hosts/home/monyarm/games/RenPy/default.nix`
- Test: archive/depot extraction fixtures

**Interfaces:**

- Steam entries consume pinned app/depot/manifest metadata and produce complete Ren'Py project roots.

- GOG entries consume pinned `fetchGOG` output and produce complete Ren'Py project roots.

- Both register through the same `mkRenPyGame` interface.

- [ ] Select `BAD END THEATER` as the Steam proof candidate unless depot inspection finds a simpler candidate.

- [ ] Select `Our Life: Beginnings & Always` as the GOG proof candidate unless the owned GOG artifact lacks a usable `game/` tree.

- [ ] Inspect each archive/depot for original Ren'Py version, project root, bundled native libraries, `.rpyc`/`.rpa` content, and writable-path assumptions.

- [ ] Preserve the full `game/` tree before attempting size optimization or engine-file removal.

- [ ] Verify the exact Steam depot/archive choice and confirm it contains the complete game data required by the shared runtime.

- [ ] Verify each wrapper independently, then register the two shortcuts.

### Task 4: Register The Remaining Strong Candidates

**Files:**

- Modify: `hosts/home/monyarm/games/RenPy/games/steam.nix`

- Modify: `hosts/home/monyarm/games/RenPy/games/gog.nix`

- Modify: reviewed catalog output

- [ ] Add verified Sakura titles in small batches, retaining the app IDs listed above.

- [ ] Add `Sakura Magical Girls` only after confirming its archive's game layout and shared-runtime compatibility.

- [ ] Add `Sunrider: Mask of Arcadius` only after confirming the GOG archive's game layout and shared-runtime compatibility.

- [ ] Record each title's original Ren'Py major/minor version and any compatibility exception in its source record.

- [ ] Reject duplicate logical game names and conflicting Steam/GOG registrations.

- [ ] Keep adult candidates out of the registry even when the catalog identifies them confidently.

### Task 5: Compatibility And Runtime-State Verification

**Files:**

- Modify: `hosts/home/monyarm/games/RenPy/mkGame.nix`

- Create: runtime-state and project-layout tests

- Modify: plan/catalog documentation if verified behavior changes

- [ ] Test a Ren'Py 7-era candidate and a Ren'Py 8-era candidate before making the current `renpyMinimal` runtime universal.

- [ ] Verify `.rpyc` and `.rpa` files remain readable from the store and that no compile/cache operation writes into the store.

- [ ] Verify save/load, persistent data, logs, and cache paths are outside immutable outputs.

- [ ] Test a title with bundled native components separately; do not add generic compatibility shims for one title.

- [ ] If the current runtime fails, first test the exact upstream runtime version recorded for that title, then add a per-game runtime override only with evidence.

- [ ] Add build-time checks for a missing `game/` directory, unsafe archive paths, and an empty extracted game tree.

## Verification

- Run the catalog parser tests and confirm the report contains the expected non-adult candidates and provider IDs.
- Confirm generated catalog/source metadata is static and no Ren'Py/VNDB/Steam API is contacted by Nix evaluation or builds.
- Build the first package with the repository's normal package target and inspect its project root for `game/`.
- Run `nix fmt` and `nix flake check`; check for another Nix process with `pgrep -x nix` before evaluation.
- Run each wrapper manually in a graphical session and test launch, save/load, audio, and persistent data.
- Confirm Steam shortcuts point at the wrapper/project root and not at a removed bundled executable.
- Verify repeated builds are reproducible and runtime-generated files do not appear under the Nix store output.
- Do not run Home Manager activation, NixOS activation, or deployment scripts as part of routine verification.
