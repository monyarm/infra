# Minecraft tooling: PrismLauncher instances, sources, pack tools, and skins

## Context

There is limited Minecraft support already: `hosts/home/monyarm/games/Minecraft.nix`
manages launcher accounts. There is not yet a declarative PrismLauncher instance,
mod, modpack, resource-pack, or datapack pipeline.

The goal is a declarative pipeline that:

- Registers Minecraft sources through `sources.toml` and resolves them during
  `update-sources.py`, not during Nix evaluation or builds.
- Builds deployable PrismLauncher instances from pinned Nix inputs.
- Exposes `games.minecraft.mods`, `modpacks`, `resourcePacks`, `datapacks`, and
  `instances` registries.
- Registers each instance as a Steam shortcut, like the existing ScummVM
  registry.
- Provides optional resource-pack and skin builders.

Modpacks are a layer under explicitly configured instance content. An instance
may have all of these first-class fields:

```nix
games.minecraft.instances.example = {
  modpacks = [ ... ];
  configs = { "example.toml" = ./example.toml; };
  datapacks = [ ... ];
  resourcePacks = [ ... ];
  mods = [ ... ];
  files = { "some/path" = ./some-file; };
};
```

Precedence is lowest to highest: modpack files, explicit mods, explicit
resource packs, explicit datapacks, `configs`, then arbitrary `files`. Duplicate
paths replace lower layers. Duplicate logical mods or packs should be rejected
unless an explicit override mechanism is added.

Datapacks are installed at `.minecraft/datapacks/`, not inside world saves.
The intended use is a datapack loader mod, so the instance-wide datapack
directory is the correct target.

The implementation must preserve mutable runtime state outside immutable Nix
outputs. Saves, logs, options, and other runtime-mutated files should use the
existing `mkOutOfStoreSymlink` pattern. Declarative `config`, `datapacks`,
`resourcepacks`, and `mods` remain store-backed.

The no-IFD rule applies throughout: HTTP, JSON, archive inspection, and source
expansion happen in `update-sources.py`; generated `sources.nix` contains plain
static values consumed by Nix fetchers and builders.

______________________________________________________________________

## Registry and instance model

Add `hosts/home/monyarm/games/Minecraft/default.nix`, while preserving the
existing `games/Minecraft.nix` launcher-account module. The home configuration
uses `autoImport`, so the new directory must be checked in before flake
evaluation.

Expose:

- `games.minecraft.mods`: nested `attrsOf (attrsOf package)`, keyed by name and
  pinned version key.
- `games.minecraft.modpacks`: resolved modpack packages or source-backed pack
  definitions.
- `games.minecraft.resourcePacks`: flat reusable resource-pack registry.
- `games.minecraft.datapacks`: flat reusable datapack registry.
- `games.minecraft.instances`: instance definitions passed to
  `mkPrismInstance`.

Datapacks are globally reusable packages, but their instance field is a list of
packages copied to `.minecraft/datapacks/`.

The module should follow:

- ScummVM's options, `_module.args`, registry folding, and `xdg.dataFile`
  pattern at `games/ScummVM/default.nix`.
- Emulation's builder injection pattern.
- Steam's `programs.steam.games` schema at
  `games/Steam/shortcuts.vdf.nix`.

Each instance becomes a synthetic Steam shortcut. The low-level builder must
not know about Steam. The Minecraft module maps an instance to PrismLauncher,
using the instance name as the launch target and deploying the instance under:

```text
~/.local/share/PrismLauncher/instances/<name>
```

______________________________________________________________________

## Stage 1 - Static source foundation

Implement update-time-resolved source records and a small Modrinth API layer.
Extend the explicit source dispatch in `update-sources.py`; do not make the
existing generic URL processor parse structured manifests.

### Individual Modrinth sources

Support project IDs and slugs, with optional selectors:

```nix
fetchModrinth {
  project = "sodium";
  minecraftVersion = "1.20.1"; # optional
  loader = "fabric";            # optional
  versionId = "...";            # optional exact pin
  filename = "...";             # optional
}
```

Behavior:

- `versionId` selects an exact version.
- `minecraftVersion` filters Modrinth `game_versions`.
- `loader` filters Modrinth `loaders`.
- With no version filter, a project or slug alone is valid and selects the
  newest published matching version.
- The update processor records the selected direct file URL, filename, API
  hashes, and Nix-compatible content hash.
- Literal pins are cached; `latest`-style selectors are explicitly rechecked
  by update operations.

Modrinth versions provide direct file URLs and SHA-1/SHA-512 hashes. Builds
should consume the recorded URL and hash, rather than resolve the API again.

Resource packs use Modrinth project type `resourcepack`. Modrinth has no
separate `datapack` project type; datapack sources are downloaded assets and
validated by their `pack.mcmeta` and layout.

Generated records should retain project, version, filename, URL, Nix hash,
API hashes, supported Minecraft versions, loaders, and asset kind.

### Modrinth modpack sources

Add a structured section such as:

```toml
[modrinth-modpack]
minecraft.modpacks.example = "project-id:version-id"
```

The version selector is optional. A project or slug alone selects the newest
pack version, optionally filtered by `minecraftVersion` and loader using the
Modrinth version-list endpoint.

The updater downloads and hashes the `.mrpack` once, parses
`modrinth.index.json`, and records:

- Minecraft and loader dependencies.
- Every file path, direct download URL, file size, SHA-1, SHA-512, and `env`.
- `overrides`, `client-overrides`, and `server-overrides` content.
- The pack archive URL and hash.

The index already contains file URLs and hashes, so individual files do not
need additional Modrinth API calls. Optional project identity enrichment can
use hash lookup later, but must not be required for the POC.

Validate every archive path as relative and reject absolute paths and `..`.
The Nix side should fetch the pinned pack archive and its listed files without
network API resolution.

______________________________________________________________________

## Stage 2 - Minimal PrismLauncher builder

Implement `games/Minecraft/mkPrismInstance.nix` and the smallest registry
needed to build one instance.

The builder should generate:

- `instance.cfg` using existing INI generators.
- `mmc-pack.json` with Minecraft and loader components.
- `.minecraft/mods` from pack and explicit mods.
- `.minecraft/resourcepacks` from pack and explicit resource packs.
- `.minecraft/datapacks` from pack and explicit datapacks.
- `.minecraft/config` from pack and `configs`.
- Arbitrary safe paths from `files`.

Use existing `linkFiles`/`parallel` helpers where suitable. Normalize all
inputs into a path map, apply the documented layer precedence, and reject
unsafe paths and unresolvable collisions.

Runtime-mutated paths such as saves, logs, and options must not be store paths.
Use persistent out-of-store locations analogous to ScummVM's saves handling.

Do not add CurseForge, alternate loaders, version aliases, skin builders, or
JAR optimization in this stage.

______________________________________________________________________

## Stage 3 - Modrinth end-to-end proof of concept

Check in one small Modrinth pack and build/deploy it through the complete path.
The instance must demonstrate:

- An arbitrary Minecraft version.
- A loader and loader version from the pack.
- Multiple mods from the pack.
- At least one resource pack.
- At least one datapack installed at `.minecraft/datapacks`.
- A pack-provided config file.
- An explicit config override.
- An arbitrary explicit file override.
- Modpack contents acting as the lower layer.
- No Modrinth API access during the Nix build.

Verify generated `instance.cfg`, `mmc-pack.json`, paths, hashes, and collision
precedence. Build verification must use the repository's normal flake checks;
launching PrismLauncher is a manual validation step, not an unattended
activation step.

______________________________________________________________________

## Stage 4 - Steam integration and complete registry

Map every `games.minecraft.instances.<name>` entry to a synthetic Steam game
option in `games/Minecraft/default.nix`. Use PrismLauncher as the executable
and launch the named instance. Keep Steam registration separate from
`mkPrismInstance`.

Add the explicit global registries:

- `mods`: direct source-backed and hand-built mod packages.
- `modpacks`: reusable resolved pack definitions.
- `resourcePacks`: resource-pack packages.
- `datapacks`: datapack packages.
- `instances`: the only entries that become Steam options.

Do not automatically promote every anonymous modpack file into the global mod
registry. If stable component registration is later desired, use Modrinth hash
lookup to recover project/version identity.

______________________________________________________________________

## Stage 5 - Standalone resource/data pack tooling

Add source processors and validators for standalone resource packs and
datapacks. Reuse `fetchHtmlThenCurl`, `process_zip`, `getFile`, and existing
hash discovery patterns.

Validate:

- ZIP or directory input.
- Root `pack.mcmeta`.
- Resource-pack versus datapack layout.
- Safe paths.
- Supported Minecraft versions when metadata provides them.

Implement `convertPack` only with a version-aware metadata mapping. Newer
Minecraft versions use different pack metadata fields, and cross-version
directory changes need explicit tables. A generic integer rewrite is
insufficient.

Implement `combinePacks` with ordered overlay semantics and deep merging for
known JSON files such as language files and `sounds.json`.

______________________________________________________________________

## Stage 6 - VanillaTweaks

Fetch VanillaTweaks resource packs and datapacks using its machine-readable
version/category JSON and generated archive endpoints. Do not package the
archived `vanillatweaks-stuff` CLI as a maintained dependency.

The updater should accept a Minecraft version and selected pack IDs, resolve
the category metadata, request the generated archive, and hash the resulting
content. Generated URLs are not durable pins; the resolved archive hash is the
reproducibility boundary.

______________________________________________________________________

## Stage 7 - PlanetMinecraft and Technic

PlanetMinecraft has no dependable public API or checksum service and may block
automated page access. Support manually selected final download URLs through
the existing URL source processor, with update-time hashing. Do not add page
scraping to the core pipeline.

Technic should support manually pinned downloads first. For Solder-backed packs,
investigate the Solder API (`/api/modpack/<slug>` and
`/api/modpack/<slug>/<version>`) for build metadata, per-mod URLs, and MD5
values. Keep this separate from CurseForge because authentication and manifest
semantics differ.

______________________________________________________________________

## Stage 8 - Randomobs and texture extraction

Research and implement `extractMobTextures` and `mkRandomobs` only after the
instance pipeline works.

OptiFine/ETF-compatible output is conventionally:

```text
assets/minecraft/optifine/random/entity/creeper/creeper.png
assets/minecraft/optifine/random/entity/creeper/creeper2.png
assets/minecraft/optifine/random/entity/creeper/creeper3.png
```

Index 1 is the base texture; alternates start at 2. Without a properties file,
variant numbering must be contiguous. If the base name ends in a digit, use a
dot separator such as `name_2.2.png`.

`mkRandomobs` must:

- Deterministically sort inputs.
- Define whether the first input becomes `mob.png` or only alternates are
  emitted.
- Never invent `mob1.png` as a vanilla replacement.
- Preserve dimensions, transparency, UV layout, and animation layout.
- Reject mixed dimensions and ambiguous duplicate variants.

`extractMobTextures` must match full resource paths, preserve texture families,
handle namespace collisions deterministically, and distinguish auxiliary eyes,
overlay, armor, marking, and cracking textures from base entity textures.

______________________________________________________________________

## Stage 9 - CurseForge and alternate sources

Implement CurseForge mod and modpack support independently from Modrinth.
CurseForge manifests provide project/file IDs but not download URLs or hashes.
Use authenticated API calls, preferably batch file lookup, and record the
resolved URL and hash in `sources.nix`.

Handle `required`, environment metadata, unavailable files, and override
collisions explicitly. Add legacy loaders and other direct-download sources
only as pinned URL assets unless a stable metadata API exists.

______________________________________________________________________

## Stage 10 - Optional skins and archive optimization

Implement `fetchSkin`, `mkSkinPermutations`, and `addHatLayer` using the existing
media transform helper.

Keep JAR optimization an opt-in experiment. A JAR is a ZIP, but Java class files
must remain byte-for-byte valid. First prove a real mod round-trips with an
identical file set and only intended image changes before exposing it as a
normal Minecraft pipeline feature.

______________________________________________________________________

## Verification

- Static source update produces pinned URLs and hashes without secrets in
  generated files.
- A Modrinth pack build performs no API resolution during Nix evaluation or
  build.
- The POC instance contains arbitrary mods, resource packs, datapacks,
  configs, and files with the documented layering.
- Datapacks appear under `.minecraft/datapacks`.
- Runtime state is outside immutable store-backed content.
- `games.minecraft.instances` produces PrismLauncher deployment and Steam
  shortcut entries.
- Resource/data pack validators reject malformed metadata and unsafe paths.
- `convertPack` is tested against real Minecraft version boundaries.
- `combinePacks` preserves keys from overlapping JSON files.
- Randomobs output uses valid OptiFine/ETF numbering and preserves source
  dimensions.
- PlanetMinecraft URL sources, Technic/Solder sources, VanillaTweaks generated
  archives, and CurseForge manifests each have separate focused tests.
- Run `nix fmt` and `nix flake check`; do not activate Home Manager or NixOS
  while verifying the implementation.
