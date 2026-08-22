# Minecraft tooling: PrismLauncher instances, fetchers, resource-pack/skin pipeline

## Context

There's no Minecraft support in this repo at all yet. The goal is a fully
declarative pipeline: fetch vanilla/loaders/mods/resourcepacks/modpacks/skins
as pinned Nix derivations, assemble them into deployable PrismLauncher
instances, and register everything in a `games.minecraft.*` registry
following the same shape as the existing `games.doom`/`games.emulation`/
`games.scummvm` registries. On top of that, a set of standalone texture/skin
builders (mkRandomobs, combinePacks, convertPack, extractMobTextures,
fetchSkin, mkSkinPermutations, addHatLayer) for building custom resource
packs and skins from arbitrary inputs.

Key architectural decision (confirmed with user): modpack manifests
(Modrinth `.mrpack` / CurseForge `manifest.json`) are resolved **in Python,
inside `update-sources.py`**, at source-update time — not read back via
`builtins.readFile` on a fetched derivation at Nix eval time. This repo has
an established no-IFD convention (`[[feedback_no_ifd]]`) and a working
build-time-only mechanism for content discovered late (`lib/optimize/ dynamic.nix`'s recursive-nix + `builtins.outputOf` trick), but for modpacks
specifically the simplest correct answer is: do the HTTP+JSON work in Python
once, bake the fully-resolved {name, version, url, hash} list for every
mod/resourcepack straight into `sources.nix` as a plain committed Nix value.
The Nix side then just `lib.mapAttrsToList fetchurl`s over that static list
(same pattern as the existing `dafont-pack` multi-FOD derivation) — no IFD,
no recursive-nix needed for this part, and modpacks *can* auto-register
their component mods/resourcepacks into the registry for free, because the
data was never behind a derivation at eval time to begin with.

Scope confirmed with user:

- Vanilla Minecraft fetcher goes all the way back to pre-2010 Classic/Indev/
  Infdev, via `skyrising/mc-versions`' extended manifest (a superset of
  Mojang's official `version_manifest_v2.json` that also covers those eras,
  hosted at https://skyrising.github.io/mc-versions/ — note some of its
  oldest entries point at archive.org URLs that have rotted since 2021, so
  the fetcher must treat per-version fetch failures as non-fatal, same as
  the existing `downloadNamedUrls` convention in `lib/fetchers.nix:194-202`).
- This is a phased plan. Each phase is independently shippable; implement
  and check in one at a time rather than attempting all of it in one pass.

______________________________________________________________________

## Phase 1 — Foundation: registry skeleton + PrismLauncher deploy + vanilla/loader fetchers

**Goal:** `games.minecraft.instances.<name>` exists, deploys a real
PrismLauncher instance (vanilla, no mods yet) to
`~/.local/share/PrismLauncher/instances/`, and launches.

**Registry module** — new `hosts/home/monyarm/games/Minecraft/default.nix`,
modeled directly on `hosts/home/monyarm/games/ScummVM/default.nix:104-196`
(options block + `_module.args` builder injection + config merge +
`xdg.dataFile` output), and `Emulation/mkRom.nix` for the builder-function
shape:

- `options.games.minecraft.enable` — same `LIGHT` env var gate as
  `games.scummvm.enable` (`ScummVM/default.nix:106-117`).
- `options.games.minecraft.instances` — `attrsOf attrs`, each fed to
  `mkPrismInstance`.
- `options.games.minecraft.mods` — **nested** `attrsOf (attrsOf package)`:
  `games.minecraft.mods.<modName>.<version>`. `<version>` is either a
  literal pinned mod-version string, or one of two resolved-at-update-time
  aliases: `"latest"` (newest published version of the mod, any MC
  version) or `"latest<mcVersion>"` e.g. `"latest1.20.1"` (newest version
  compatible with that specific Minecraft version). Both aliases are
  resolved to a concrete file+hash by `update-sources.py` (see Phase 2) —
  the alias string is only ever a registry *key*, never something Nix
  resolves at eval time. Re-running `update-sources.py --append` re-checks
  every `latest`/`latest<mcVersion>` entry for a newer match each run
  (same as the existing plain-`latest` re-check behavior already in
  `process_modrinth`/`process_curseforge`, `update-sources.py:1308-1309, 1340-1341`); literal version keys are cached and skipped once resolved.
- `options.games.minecraft.resourcePacks` / `.skins` — flat `attrsOf package`, populated both by hand-written entries and (Phase 2)
  auto-population from modpack sources.
- `imports = autoImport ./instances` (+ `./mods`, `./resourcepacks`,
  `./skins` in later phases), same `autoImport` helper ScummVM/Emulation use.

**`mkPrismInstance` builder** — new `Minecraft/mkPrismInstance.nix`:
takes `{ name, minecraftVersion, loader ? null, loaderVersion ? null, mods ? [], resourcePacks ? [], shaderPacks ? [], javaArgs ? {}, ... }@args` and
returns a derivation tree for one instance directory:

- `instance.cfg` — generated via `lib.generators.toINI` (already used for
  `scummvm.ini` in `ScummVM/default.nix:189`) from `javaArgs`/window
  size/etc.
- `mmc-pack.json` — generated JSON: base `net.minecraft` component (uid/
  version from `minecraftVersion`) plus, if `loader != null`, the matching
  loader component (`net.fabricmc.fabric-loader`, `net.minecraftforge`,
  `net.neoforged`, `org.quiltmc.quilt-loader`).
- `.minecraft/mods`, `.minecraft/resourcepacks`, `.minecraft/shaderpacks` —
  built via the existing `linkFiles`/`parallel` helpers (`ScummVM/ default.nix:191`) symlinking each entry from `mods`/`resourcePacks`/
  `shaderPacks` by filename.
- `.minecraft/saves`, `.minecraft/logs`, `.minecraft/config`,
  `.minecraft/options.txt` — **not** store paths: PrismLauncher writes to
  these at runtime (confirmed instance dirs need write access for saves/
  logs/options). Use `mkOutOfStoreSymlink` to a persistent
  `${dirs.hmConfig}/Minecraft/instances/<name>/...` dir, exactly like
  ScummVM's `saves` symlink (`ScummVM/default.nix:193`).

**Deploy site:** `xdg.dataFile."PrismLauncher/instances/<name>"` per
instance, same shape as ScummVM's `xdg.dataFile` block.

**Vanilla + loader fetchers** — new `lib/fetchers/minecraft.nix`, wired into
`lib/fetchers.nix`'s existing merge the same way `dafont.nix` etc. are:

- `fetchMinecraftVersion = { version, sha1 }: pkgs.fetchurl {...}` — resolves
  the client jar URL for a given version ID against the pinned manifest data
  (see sources.toml entry below); one derivation per version.
- `fetchFabricLoader`, `fetchQuiltLoader` — both have clean versioned APIs
  (`meta.fabricmc.net`, `meta.quiltmc.org`); use the `fetchHtmlThenCurl`
  pattern (`lib/fetchers.nix:138-192`) already used by `fetchModrinth`/
  `fetchCurseForge`.
- `fetchForge`, `fetchNeoForge` — no clean JSON API (Maven directory
  listing only); resolve via their maven-metadata.xml, same
  `fetchHtmlThenCurl` shape.
- Legacy loaders for old modpacks (Risugami's ModLoader, ancient Forge for
  1.2.5-era Tekkit, LiteLoader) have no API at all — don't build bespoke
  fetchers for these; pin them as plain `[url]`/`[zip]` entries in
  `sources.toml` like any other static asset.

**sources.toml additions** (new `[minecraft-version]` section type) +
`update-sources.py`: new `process_minecraft_version(name, version_id, previous_sources)` alongside the existing `process_modrinth`/
`process_curseforge` (`update-sources.py:1286-1357`) — fetches
`skyrising/mc-versions`' manifest once per run, resolves `version_id` to its
client-jar URL + sha1, writes `{"type": "minecraft-version", "id": version_id, "url": ..., "hash": ...}` into `sources.nix`. Same
`--append`-only, cache-if-unchanged pattern as the existing processors.

______________________________________________________________________

## Phase 2 — Modrinth/CurseForge fetchers: single files + modpack expansion

**Goal:** individual mods/resourcepacks fetchable by project/mod id (already
half-done — `fetchModrinth`/`fetchCurseForge` in `lib/fetchers/modrinth.nix`
and `curseforge.nix` already exist and are wired into `update-sources.py`'s
`process_modrinth`/`process_curseforge`, lines 1286-1357). New work is (a)
the `<modName>.<version>` nested-key registry shape including `"latest"` /
`"latest<mcVersion>"` resolution, and (b) the **modpack** case.

**Version-alias resolution** (extends the existing single-mod processors,
not the modpack ones): `sources.toml` entries for mods gain a
`<modName>.<versionKey>` dotted-key shape, e.g.:

```toml
[modrinth]
sodium.latest = "AANobbMI"
sodium."latest1.20.1" = "AANobbMI"
sodium."0.5.8" = "AANobbMI"
```

`process_modrinth`/`process_curseforge` parse the trailing key segment as
the version selector: bare `latest` keeps today's behavior (`sort_by (.date_published) | last`, `update-sources.py:1336`); `latest<mcVersion>`
adds Modrinth's `game_versions` query param (`?game_versions=["<mcVersion>"]`
on the version-list endpoint) / CurseForge's files-endpoint `gameVersion`
filter before taking the newest match; a literal version string is passed
through as an explicit `versionId`/`fileId` pin exactly as today. Each
resolved result is written into `sources.nix` keyed by the full
`<modName>.<versionKey>` path, which `Minecraft/mods/default.nix` then maps
1:1 into `games.minecraft.mods.<modName>.<versionKey>`.

**`update-sources.py` extension:** new `process_modrinth_modpack` /
`process_curseforge_modpack`, triggered by a `[modrinth-modpack]`/
`[curseforge-modpack]` sources.toml section (parallel to the existing
`[modrinth]`/`[curseforge]` single-file sections at
`update-sources.py:1580-1583`), with optional version pinning (`name = "project:versionId"` syntax, matching how `[github-release]` entries already
pin a tag prefix). Each processor:

1. Resolves+downloads the pack file itself (`.mrpack` is a zip; CurseForge
   pack is a zip with `manifest.json` + `overrides/`) via the same
   `http_get`/API-key handling `process_curseforge`/`process_modrinth`
   already use.
1. Parses `modrinth.index.json` (`files[]`: `path`, `hashes.sha1`,
   `downloads[]`, `env`) or `manifest.json` (`files[]`: `projectID`,
   `fileID`, `required` — each resolved to a real download URL via one
   CurseForge API call per file, same auth as `process_curseforge`).
1. Writes a nested structure into `sources.nix`: `{type = "modrinth-modpack"; minecraftVersion; loader; loaderVersion; files = { <name> = {url; hash; path; env}; ... }; overrides = <fetched overrides dir hash>; }`.

**Nix side** — new `Minecraft/modpacks/mkModpack.nix`: given a
`sources.modpacks.<name>` entry (now a plain static Nix value, see Context),
`lib.mapAttrsToList` generates one `fetchurl` per file — same pattern as
`dafont-pack` in `hosts/home/monyarm/config/Fonts.nix` (multi-FOD
`stdenv.mkDerivation` with `srcs = lib.mapAttrsToList fetchX manifest;`).
Files with `path` under `resourcepacks/`/`shaderpacks/` route there instead
of `mods/`. Feeds straight into `mkPrismInstance`'s `mods`/`resourcePacks`
args.

**Auto-registration into the registry:** because `sources.modpacks.<name>`
is already a fully-resolved static value (no IFD needed), `Minecraft/ modpacks/default.nix` can `lib.mapAttrs'` over its `files` and merge each
mod into `games.minecraft.mods.<modName>.<resolvedVersion>` (resourcepacks
still go into the flat `games.minecraft.resourcePacks`) via
`lib.recursiveUpdate` — this is the piece that specifically required the
Python-side resolution decision from the Context section above.

**Technic/PlanetMinecraft/VanillaTweaks:**

- Technic/PlanetMinecraft have no API; both are direct-download-link sites.
  Add `[technic]`/`[planetminecraft]` as thin sources.toml `[url]`-style
  entries (or literally reuse the existing `[url]` section) — no new
  processor needed, they're just pinned download links.
- VanillaTweaks: wrap the community `vanillatweaks-stuff` CLI
  (github.com/OmerMakesStuff/vanillatweaks-stuff) as a new `packages/ vanillatweaks-cli.nix` (same `mkPythonToolWrapper`/similar wrapper shape
  as `packages/mmlc-dac-extractor.nix`), then `Minecraft/fetchVanillaTweaks.nix`
  invokes it inside a fixed-output derivation (`outputHashMode = "recursive"`,
  network-enabled build) given a pack-name list + target MC version.

______________________________________________________________________

## Phase 3 — research: mod jars through `lib/optimize`

**Goal:** answer whether `.jar` mods can go through the existing
`lib/optimize/` pipeline for texture/asset compression, and wire it in if
so — no separate builder needed if this works.

A JAR is a ZIP; `lib/optimize/`'s dispatcher already handles nested
archives (`.pk3`/`.ipk3` mentioned as already-handled nested-archive cases
per the emulation-pipeline exploration). The research task is: check
`lib/optimize/default.nix`'s extension dispatch table and `archive.nix`'s
nested-archive handling, and determine whether adding `.jar` (and
`.mrpack`) to that table is sufficient, or whether jar-internal binary
`.class` files need to be excluded from whatever the generic handler does
(they must pass through byte-for-byte — corrupting them breaks the mod).
Verify with a real mod jar that round-trips through `optimize` unchanged
except for its embedded PNGs, and that the existing "revert if optimized
output isn't smaller" guard still protects against jar corruption.

______________________________________________________________________

## Phase 4 — Resource-pack builders: convertPack, combinePacks, extractMobTextures, mkRandomobs

All four live under a new `Minecraft/resourcepacks/builders/` directory and
reuse `lib/files.nix`'s `getFile`/`splitFiles`/`removeFiles`
(`lib/files.nix:317-352`) plus the `stageFiles`/`stagedNames` shell-escaping
helpers from `lib/compressRom/default.nix` for any multi-file staging.

- **`convertPack.nix`** — `{ pack, targetVersion }`: patches
  `pack.mcmeta`'s `pack_format` integer via `jq` (format-to-version mapping
  is a static lookup table, no external tool needed for the common case).
  Research whether cross-major-version structural moves (e.g. 1.13's
  `textures/blocks` → `textures/block` flattening) are in scope; if so,
  those need an explicit per-version-range rename table, not a generic CLI.
- **`combinePacks.nix`** — `{ packs }` (ordered list, later entries win):
  `pkgs.runCommand` copying each pack's tree in order (later overwrites
  earlier, standard `cp -rT` loop) for normal files, then a `jq -s 'reduce .[] as $x ({}; . * $x)'` deep-merge pass specifically for JSON files
  (`lang/*.json`, `sounds.json`) so language packs merge instead of
  clobbering — no existing deep-merge helper in the repo, this is new but
  trivial (matches the exploration finding that `jq -s` is the right tool,
  just not yet wrapped).
- **`extractMobTextures.nix`** — `{ jar, mobPattern }`: scans a mod jar
  (or folder) for texture paths matching a glob/regex, extracts+renames
  them via `getFile`/`splitFiles`, output is a plain folder derivation
  suitable as `mkRandomobs`'s input — same shape as the emulation
  extractors (`neogeo-rom-extractor`, `mmlc-dac-extractor`) that scan an
  archive for pattern-matched members.
- **`mkRandomobs.nix`** — `{ sources, mobName }` where `sources` is folders/
  zips/individual PNGs: extracts+sequentially numbers into OptiFine/ETF's
  `mob.png`, `mob2.png`, ... convention. `pkgs.runCommand` doing a sorted
  walk + rename loop.

______________________________________________________________________

## Phase 5 — Skin builders: fetchSkin, mkSkinPermutations, addHatLayer

Reuse `lib/media.nix`'s `transform` function (`lib/media.nix` — the
`pkgs.runCommand` + ImageMagick `magick` wrapper already used for wallpaper
crop/grow, content-addressed per-output) as the base for all region-slicing
here, rather than writing new ImageMagick plumbing from scratch.

- **`fetchSkin.nix`** — `{ url }` or `{ username }` (resolves via Mojang's
  session-server API to the current skin URL, then fetches): thin
  `pkgs.fetchurl`, same convention as other single-file fetchers.
- **`mkSkinPermutations.nix`** — `{ heads, torsos, legs, combine ? <default cartesian> }`: slices each 64×64 skin into its three named
  regions via `media.nix`'s `transform` (one crop-derivation per region per
  input skin — cheap, cached individually), then `combine` (an eval-time
  function, overridable, defaulting to full cartesian product via
  `lib.cartesianProduct` or manual nested `map`) produces an **attrset**
  keyed by combo name, each value its own composite derivation. This is
  the mechanism that satisfies "adding one input doesn't rebuild
  everything": because the registry is a lazy Nix attrset generated by
  `map`/`lib.cartesianProduct`, not a single derivation, only the *new*
  combos' derivations are realized on `nix build`; existing ones are
  untouched (same principle as `media.nix`'s pre-generated crop-function
  table and the emulation pipeline's `lib.listToAttrs (map ...)` per-variant
  derivations).
- **`addHatLayer.nix`** — `{ bodies, hats }` (two lists): same
  cartesian-attrset mechanism as above, composing via ImageMagick
  `-composite` instead of crop.

______________________________________________________________________

## Verification

- **Phase 1:** `nix build .#legacyPackages.x86_64-linux.<a-test-instance>`
  (or the equivalent `homeConfigurations` eval) succeeds; inspect the built
  instance dir has valid `instance.cfg`/`mmc-pack.json`; actually launch
  PrismLauncher with it deployed and confirm vanilla Minecraft boots.
- **Phase 2:** build a real small Modrinth modpack (e.g. Fabulously
  Optimized) end-to-end; diff the resolved mod list against the modpack's
  published mod list; confirm `games.minecraft.mods` contains each one.
- **Phase 3:** build a mod jar through `optimize`, diff its zip listing
  before/after (must be identical file set, only PNG bytes may change),
  confirm the mod still loads in-game.
- **Phase 4:** run `combinePacks` on two packs with overlapping
  `lang/en_us.json` keys, confirm both packs' keys survive in the merged
  output; run `convertPack` on a pack across a `pack_format` boundary and
  load it in-game to confirm no missing-texture warnings.
- **Phase 5:** build one `mkSkinPermutations` combo, confirm image
  dimensions/regions are correct by eye; add one new head input and
  confirm only the new combos rebuild (`nix build --dry-run` diff).
