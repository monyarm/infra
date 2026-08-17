# Rename + broaden scummvm-library-scan into game-library-scan

## Context

`packages/scummvm-library-scan.nix` cross-references owned games (GOG/Epic/Steam/Maxima=EA-Origin) against `scummvm --list-games` to find which owned titles are playable via ScummVM. The user wants it broadened to also flag owned games that bundle a Doom-engine IWAD/PWAD playable in gzdoom/uzdoom — not just id/Raven's official catalog, but any commercial game (including indie GZDoom total conversions) that ships a wad — since there's no queryable API for that (unlike ScummVM's own list), that side needs a hand-researched table (built via targeted web research, not guessed). Both sections should merge multiple owning sources for the same match onto one line, support filtering to a single category via CLI flags, and exclude wads/games already registered in this repo — using this repo's own home-manager config as the source of truth, not an ad hoc runtime `nix eval`.

Confirmed with user (round 2 of feedback on round 1's plan):

- Doom-wad scope: broad — any IWAD/PWAD playable in gzdoom/uzdoom (Doom, Heretic, Hexen, Strife, HACX, indie GZDoom titles), not just id-Software-branded wads.
- New filename: `packages/game-library-scan.nix` (package `game-library-scan`).
- Need `--scummvm` / `--doom` flags to show a single category only.
- Since this ships as a Nix package built from this same flake, bake the "already defined" set in at build/switch time via a home-manager-generated JSON file, instead of shelling out to `nix eval` at runtime.
- Doom table isn't limited to official titles — indie/commercial games with a wad count too, matched against the same owned Steam/GOG/Epic/Maxima libraries the ScummVM side already fetches (no new fetcher needed).
- Exclusion must be per-wad, not per-row: a table row is only skipped if **every** wad it lists is already defined in this repo. A row with 4 new wads and 1 already-owned wad still shows (with the already-had one annotated, not silently dropping the row).
- Wad-id comparisons are case-insensitive (lowercase both sides before set membership checks).

## Existing pieces to reuse (no reinvention)

- `build_index()` / `fuzzy_matches()` — generic over any `(id, name)` list; reuse unchanged for the Doom-bundle table (treated like a second, much smaller `scummvm_games()`-style list).
- `normalize()`, `NOISE_RE`, `significant_words()` — unchanged, shared by both sections.
- The four fetchers (`gog_titles`, `epic_titles`, `steam_titles`, `maxima_titles`) — unchanged; still the only source of "what does the user own," used for both sections.
- `autoImport ./games` (`hosts/home/monyarm/default.nix:13`) already picks up any top-level `*.nix` file dropped directly in `hosts/home/monyarm/games/` (e.g. `Desmume.nix`, `Minecraft.nix` sit alongside the `Doom/`/`ScummVM/` directories) — new module goes there, no extra wiring.

## Doom-bundle table — research findings (targeted searches, not guesses)

Searched "Steam/GOG games that bundle a doom wad", "GZDoom commercial indie games Steam", etc. directly, per your suggestion. Findings:

**Official id/Raven/Rogue catalog** (GOG's page groups these explicitly; Steam sells the same set individually and as "DOOM Classic Complete"):
Doom, Doom II, Final Doom, Master Levels for DOOM II, DOOM 3: BFG Edition, DOOM + DOOM II (2019 unified re-release), DOOM 64, Heretic: Shadow of the Serpent Riders, Hexen: Beyond Heretic, Hexen: Deathkings of the Dark Citadel, Heretic + Hexen (2025 Nightdive remaster), Strife: Veteran Edition, DOOM Classic Complete Pack. HACX and Chex Quest are freeware, not normally sold on GOG/Steam — kept in the table anyway since a store listing costs nothing to check for and this repo doesn't have either wad yet.

**Indie/commercial GZDoom-engine standalone games actually sold on Steam/GOG** (Doomworld's "every GZDoom game on Steam" thread + Doom Wiki's indie-games page):
REKKR: Sunken Land, Ashes 2063 (+ Ashes Afterglow), Hedon Bloodrite, Selaco, Vomitoreum, The Adventures of Square, Lycanthorn, Lycanthorn II, DOOM: The Golden Souls Remastered (already have `goldenSoulsRemastered` from itch — this row will self-exclude if owned on Steam too, proving the per-wad exclusion works across sources).

This list is inherently non-exhaustive (there's no upstream machine-readable index the way ScummVM has `--list-games`) — treat it as a living table to extend later, same as the existing `DOOM_BUNDLE_GAMES`-style approach already used for ScummVM matching.

### Table (`DOOM_BUNDLE_GAMES`, each row: id, title, wad_ids)

| id | title | wad_ids | note |
|---|---|---|---|
| `doom_ultimate` | The Ultimate DOOM | `doom` | |
| `doom2` | DOOM II: Hell on Earth | `doom2` | |
| `final_doom` | Final DOOM | `tnt`, `plutonia` | |
| `master_levels` | Master Levels for DOOM II | `masterlevels` | |
| `doom3_bfg` | DOOM 3: BFG Edition | `doom`, `doom2`, `nerve` | censored variants, still same ids |
| `doom_doom2_unified` | DOOM + DOOM II | `doom`, `doom2`, `tnt`, `plutonia`, `masterlevels`, `nerve`, `sigil`, `sigil2`, `id1` | |
| `doom64` | DOOM 64 | `doom64` | |
| `heretic` | Heretic: Shadow of the Serpent Riders | `heretic` | new |
| `hexen` | Hexen: Beyond Heretic | `hexen` | new |
| `hexen_deathkings` | Hexen: Deathkings of the Dark Citadel | `hexendeathkings` | new |
| `heretic_hexen_remaster` | Heretic + Hexen | `heretic`, `hexen`, `hexendeathkings` | new |
| `strife` | Strife: Veteran Edition | `strife` | new |
| `hacx` | HACX: Twitch 'n Kill | `hacx` | new, freeware |
| `chex_quest` | Chex Quest | `chex` | new, freeware |
| `doom_classic_complete` | DOOM Classic Complete Pack | `doom`, `doom2`, `tnt`, `plutonia`, `masterlevels`, `heretic`, `hexen`, `hexendeathkings`, `strife` | |
| `rekkr` | REKKR: Sunken Land | `rekkr` | new, indie |
| `ashes_2063` | Ashes 2063 | `ashes2063` | new, indie |
| `ashes_afterglow` | Ashes Afterglow | `ashesafterglow` | new, indie |
| `hedon_bloodrite` | Hedon Bloodrite | `hedon` | new, indie |
| `selaco` | Selaco | `selaco` | new, indie |
| `vomitoreum` | Vomitoreum | `vomitoreum` | new, indie |
| `adventures_of_square` | The Adventures of Square | `adventuresofsquare` | new, indie |
| `lycanthorn` | Lycanthorn | `lycanthorn` | new, indie |
| `lycanthorn_2` | Lycanthorn II | `lycanthorn2` | new, indie |
| `golden_souls_remastered` | DOOM: The Golden Souls Remastered | `goldensoulsremastered` | already have via itch — proves cross-source exclusion |

All `wad_ids` written lowercase (matching the case-insensitive comparison below); this repo's actual attrset keys (e.g. `masterLevels`, `hexenDeathkings`, `goldenSoulsRemastered`) get lowercased at comparison time, not renamed.

## Changes to `packages/game-library-scan.nix` (git mv from `scummvm-library-scan.nix`)

### 1. CLI flags

`--scummvm` and `--doom` (mutually inclusive, not exclusive — either alone shows just that section; neither/both shows both, same as today). Implemented as a simple `argparse` pair plus `show_scummvm = args.scummvm or not args.doom` / `show_doom = args.doom or not args.scummvm` gate around each section in `main()`.

### 2. Doom-bundle table + reused matcher (as above)

### 3. Already-defined data: home-manager-baked JSON, not runtime `nix eval`

New file `hosts/home/monyarm/games/game-library-scan.nix` (picked up automatically by `autoImport ./games`):

```nix
{ config, lib, ... }:
{
  xdg.dataFile."game-library-scan/already-defined.json".text = builtins.toJSON {
    doomWads = builtins.attrNames config.games.doom.wads;
    scummvmGameids = map (g: g.gameid or g.engineid) (builtins.attrValues config.games.scummvm.games);
  };
}
```

This regenerates on every `home-manager switch`, so it always reflects the currently-activated generation — no flake re-eval at scan time. The script just reads it:

```python
def already_defined():
    path = Path.home() / ".local" / "share" / "game-library-scan" / "already-defined.json"
    if not path.exists():
        print(f"Warning: {path} not found (run `home-manager switch` first?), showing everything.", file=sys.stderr)
        return {"doomWads": [], "scummvmGameids": []}
    data = json.loads(path.read_text())
    return {
        "doomWads": {w.lower() for w in data.get("doomWads", [])},
        "scummvmGameids": set(data.get("scummvmGameids", [])),
    }
```

Known limitation (noted, not engineered around): `games.scummvm.games`/`games.doom.wads` entries are individually wrapped in `lib.mkIf config.games.scummvm.enable { ... }` by their defining files, so a `LIGHT=1` build (which flips that `enable` default off) would bake an empty exclusion set. Fine for this tool's normal (non-`LIGHT`) usage.

### 4. Per-wad, not per-row, exclusion

```python
def annotate_wads(wad_ids, have):
    return [(w, w.lower() in have) for w in wad_ids]

def doom_row_fully_owned(wad_ids, have):
    return all(w.lower() in have for w in wad_ids)
```

A row is skipped only when `doom_row_fully_owned` is true. Otherwise it's shown with each wad id marked, e.g. `tnt(have) plutonia(NEW)`, so a 4-new/1-had row still surfaces with the already-had one visibly called out instead of silently vanishing.

ScummVM-side exclusion (single id per row, so this reduces to skip-if-in-set): skip a matched `gid` if it's in `scummvmGameids`.

### 5. Merge-sources-per-line output (rewrite of `main()`'s printing loop)

Same as round 1: pivot from `source -> title -> matches` to `matched target -> [(ratio, source, title), ...]`, one printed line per target:

```python
def collect_matches(sources, index, threshold):
    by_target = {}
    for source, titles in sources.items():
        for title in sorted(set(titles)):
            for ratio, gid, name in fuzzy_matches(title, index, threshold):
                by_target.setdefault(gid, {"name": name, "hits": []})
                by_target[gid]["hits"].append((ratio, source, title))
    return by_target
```

```
God of Thunder [got]  <-  GOG: 'God of Thunder' (0.93), Steam: 'God of Thunder' (0.91)
```

Doom section prints under its own `=== Doom-engine WAD games ===` header, using `DOOM_BUNDLE_GAMES`'s `wad_ids` (with per-wad have/new annotation) rather than a fuzzy target id for the exclusion check.

### 6. No changes needed to fetchers, `normalize`, `NOISE_RE`, `significant_words`, `build_index`, `fuzzy_matches`, `get_secret`, `scummvm_games()`.

## Verification

- `nix build .#game-library-scan` — confirms the Python still parses cleanly (`writers.writePython3Bin` runs `flake8` at build time).
- `home-manager switch` (or `nix build .#homeConfigurations.monyarm.activationPackage` if a dry check is preferred) then confirm `~/.local/share/game-library-scan/already-defined.json` exists and contains the expected `doomWads`/`scummvmGameids` — spot check a couple of known ids (`doom`, `got`).
- `nix run .#game-library-scan -- --help` — confirms `--scummvm`/`--doom` are wired.
- `nix run .#game-library-scan -- --doom` and `-- --scummvm` — confirm each shows only its section.
- Full end-to-end run (`nix run .#game-library-scan`) needs real GOG/Epic/Steam/Maxima secrets in `secrets/env.json` — run it live, confirm merged multi-source lines render correctly, confirm already-registered ids (`got`, `doom`) don't reappear as fully-owned rows, and confirm a partially-owned Doom row (if any owned title happens to match one) shows per-wad have/new annotation instead of disappearing.
