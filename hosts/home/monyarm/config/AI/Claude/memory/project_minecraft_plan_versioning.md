---
name: project-minecraft-plan-versioning
description: Minecraft/PrismLauncher plan design decisions on mod/modpack versioning that reverse an earlier over-trim
metadata: 
  node_type: memory
  type: project
  originSessionId: 5ac9d091-64cb-4c8b-bf5a-bdba0522e8d0
---

The Minecraft Modrinth plan (`.claude/plans/read-claude-plans-minecraft-md-it-s-wise-conway.md`)
went through two rounds of correction from an initial over-trimmed pass
(flat `attrsOf package`, latest-version-only). Final design:

- `games.minecraft.mods`/`resourcePacks`/`datapacks` are nested
  `attrsOf (attrsOf package)` keyed by Modrinth versionId, tracking ALL
  published versions — but populated ONLY from mods the user explicitly
  registers via a `[modrinth]` sources.toml entry. A modpack's own bundled
  mods are NOT promoted into this registry; `fetchModrinthModpack` fetches
  them directly from the pack's own `modrinth.index.json`. A custom
  modpack's text-based `mods = { sodium = "latest"; }` can only reference
  names already in the explicit registry.
- Tracking all versions of an explicit mod is cheap, not heavy: Modrinth's
  version-list API already publishes a sha512 per file, and for a
  single-file fetch that published hash IS the correct Nix output hash —
  no `nix build` hash-discovery trial needed, just hex→SRI-base64
  conversion in Python. Only the modpack's assembled multi-file output tree
  still needs one nix-build-discovered aggregate hash per pack version
  (unavoidable — Nix requires a real outputHash on any FOD doing
  build-time network I/O), but that's O(modpack versions), not O(mod files).
- `update-sources.py` must diff each project's version-id set against the
  previous `sources.nix` run and only process new ids — never
  re-fetch/re-hash already-known versions.
- `games.minecraft.games.<name>.minecraftVersion`/`loader`/`loaderVersion`
  default to null and fall back to the resolved modpack's `dependencies`;
  they're only required to be set explicitly when no modpack is set.
  `modpackVersion` defaults to `"latest"`.
- `lib/fetchers.nix`'s `fetchHtmlThenCurl` needs `outputHashAlgo` made
  overridable (currently hardcoded `"sha256"`) so Modrinth fetches can use
  `"sha512"` and consume the API hash directly.

**Why:** the "latest compatible" resolution only works if every candidate
version is already hash-pinned in `sources.nix` (no live lookup at eval
time) — but that's only worth doing for mods the user actually wants
addressable/reusable, not every transitive dependency of every modpack.

**How to apply:** if continuing or re-deriving this plan, don't re-trim to
flat/latest-only registries, and don't cascade a modpack's own mods into
the global mods registry — both were tried and explicitly rejected.

Third round of correction (now reflected in the plan's final multi-stage
form, `.claude/plans/read-claude-plans-minecraft-md-it-s-wise-conway.md`):
- No "assembled tree" hash for modpacks either — since `update-sources.py`
  already opens the `.mrpack` archive to read `dependencies`, it also reads
  `modrinth.index.json`'s `files[]` (each already carrying its own hash)
  and bakes that whole per-file list into `sources.nix`. Nix then fetches
  each file individually via plain `pkgs.fetchurl` with its own known hash
  — no fetcher-internal curl loop, no nix-build hash discovery for
  modpacks at all. This same "hash is already published, pipe it straight
  into fetchurl" principle turned out to extend to PrismLauncher's own
  meta service and Mojang's piston-meta (both publish per-library/per-asset
  hashes the same way Modrinth does).
- Version-table keys are the human-readable Modrinth `version_number`
  (e.g. `"0.5.8"`), not the opaque `versionId` — so explicit pins read
  naturally in Nix config.
- `pickModVersion` selector grammar: `"latest"` (exact minecraftVersion+
  loader match), `"latestMajor"` (major.minor match, ignores patch),
  `"latestIKnowWhatImDoing"` (no minecraftVersion filter at all), any of
  which can take a `":loader"` suffix to override the loader independently
  (e.g. `"latest:quilt"`). A bare version-number string is a literal pin.
- `games.minecraft.mods`/etc. are NixOS `attrsOf` options auto-populated
  from `sources.nix` as a plain config contribution (not `option.default`)
  so hand-written entries in other files still merge in via normal
  attrsOf semantics — both is required, not either/or.
- The instance builder needs to fetch not just the modpack's own content
  but PrismLauncher's shared `libraries/`+`assets/` cache and Mojang's
  client jar/assets too, or the instance can't actually launch — this
  needed a dedicated research task (Task 7 in the plan) before designing
  the fetcher, since PrismLauncher's on-disk instance format
  (`mmc-pack.json`/`patches/<uid>.json`) needs verifying against a real
  installed instance rather than assumed from the network meta format alone.
