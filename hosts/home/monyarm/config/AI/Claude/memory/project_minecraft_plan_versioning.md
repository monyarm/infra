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

**Implementation status: all 10 plan tasks done and verified** (as of
2026-09-07). Built and inspected two real instances end-to-end: the actual
Society Sunlit Valley pack (325 correctly-named mod jars, real
`mmc-pack.json` with `net.minecraft`→`org.lwjgl3` cachedRequires) and a
hand-built custom pack proving `jei = "latest"` correctly resolves the
newest of 3499 tracked JEI versions matching 1.20.1+forge. Layering
precedence (explicit `configs` override beats modpack-provided file at the
same path) verified by direct rebuild-and-diff.

Real bugs found only by actually building (not just `nix eval`), worth
remembering for any similar "fetch external ecosystem data into sources.nix
verbatim" work:
- `lib/fetchers.nix`'s `fetchHtmlThenCurl` needed the `outputHashAlgo`
  override *and* `fetchModrinth` needed to actually detect the algo from
  the hash string's `sha256-`/`sha512-`/`sha1-` SRI prefix — adding the
  override alone without wiring the detection silently kept hardcoding
  sha256, which only surfaced as a Nix hash-type-mismatch error at build
  time, not eval time.
- A module-local builder split into its own file (mirroring ScummVM's
  inline `mkScummVMGame`, but as a separate `mkPrismInstance.nix`) is
  **not** automatically available like `customLib` functions are — it must
  be explicitly `import`ed and its result destructured in the consuming
  module. Assuming otherwise produces an `_module.args` "attribute missing"
  error only at eval time of a consumer, not at the file's own creation.
- `update-sources.py`'s generic `to_nix_val` serializer fell through
  Python's `None` to `str(None) == "None"` (invalid Nix) — fixed generically
  (not just avoided in one call site) since any future fetcher emitting an
  absent-field `None` would hit the same bug.
- Nix's `linkFiles` (`lib/files.nix`) produces a home-manager
  `xdg.dataFile`-shaped attrset, not a buildable directory — wrong tool for
  composing directories inside a pure Nix builder function. `pkgs.linkFarm`
  (stdlib) is the right primitive for "place a list of packages at their
  own name inside one directory" when you need a real derivation back, not
  a home-manager file-spec.
- Large sequential archive downloads (a 12-version, ~700MB total `.mrpack`
  history) hit real Cloudflare/CDN throttling and an `IncompleteRead` after
  ~50 minutes on the very last version, discarding the whole run since
  `update-sources.py` only wrote `sources.nix` on full success. Fixed with
  retry-with-backoff in `http_get` plus per-version try/except in
  `process_modrinth_modpack` so partial progress within one run survives a
  single version's failure.
- PrismLauncher meta's `net.fabricmc.fabric-loader`/`org.quiltmc.quilt-loader`
  version files use a third `libraries[]` shape (`{name, url}` where `url`
  is a Maven *repo base*, not a full artifact URL, and no published hash)
  — different from Mojang/Forge's `downloads.artifact.{url,sha1}` shape.
  **Now implemented** (follow-up session, same day): construct the real
  artifact URL (`mavenCoordToPath` + repo base) and fetch its standard
  Maven `.sha1` sidecar — stays metadata-only, no nix-build discovery.
  Some legacy Forge-era entries omit `url` entirely too, implying Mojang's
  default repo (`libraries.minecraft.net`, confirmed live).

**Follow-up session (same day) — real production hardening, in order
encountered:**
- `sources.toml`'s `[prism-component]` entries changed from one pinned
  version each to a bare component uid, tracking *every* version (6610
  total across net.minecraft/net.minecraftforge/fabric-loader/quilt-loader)
  — same all-versions shape as `[modrinth]`, since a component's own
  `index.json` doesn't carry full per-version library data the way
  Modrinth's version-list API does.
- A component with thousands of versions means one HTTP request per
  version if fetched individually (`net.minecraftforge` has 5032) — fixed
  by downloading the `PrismLauncher/meta-launcher` GitHub repo as one
  tarball past a 200-new-version threshold (confirmed byte-identical to
  the live API) and reading every version locally.
- `http_get` initially got a blind HTTPError retry added on the *wrong
  premise* (assumed transient load-based 404s) — user pushed back,
  correctly: re-tested the exact failing URL in isolation and it 404's
  permanently, on Maven Central too, not just under load. Reverted the
  retry; added disk-persisted success/failure memoization instead
  (`.maven-sidecar-cache.json`, gitignored) so a dead coordinate is
  looked up once per script lifetime, not once per version referencing it
  (measured 5x+ duplication: fabric-loader alone is 2421 (version,
  library) pairs across only 422 distinct coordinates).
- A single missing dependency was sinking an entire component version
  (some legacy Forge builds reference Scala/ASM jars no longer hosted
  anywhere) — fixed to omit just that one library and keep the rest;
  mattered a lot in practice, since Minecraft 1.12.2 (the most heavily
  modded version ever) would otherwise have ended up entirely
  unregistered over two missing Scala jars.
- **Real, costly bug**: extracting the sources.nix write into
  `write_sources_nix()` and reverting a (rejected) per-entry incremental
  -write experiment dropped the actual call to it at the end of `main()`
  — a full ~6610-version bulk fetch completed successfully in memory and
  was silently discarded because nothing ever wrote it to disk. Caught by
  checking `sources.nix` after a "successful" run and finding the new data
  simply wasn't there.
- **Real, costly bug**: `builtins.listToAttrs` keeps the *first* matching
  name on duplicates, not the last (see
  `feedback_listtoattrs_first_wins.md`) — orphaned single-version
  `prism-component` entries left over from early testing shared a `uid`
  with the new all-versions entries and sorted first alphabetically, so
  `getComponent` kept resolving to stale data no matter how the new data
  was fixed. Fixed by filtering to entries with a `versions` field before
  building the uid lookup table, then removed the orphaned entries from
  `sources.nix` entirely (they were also a needless duplication risk).
- Also fixed: `mkPrismComponentLibraries` now also places a component's
  `mainJar` (this is what covers `minecraft.jar` itself, not just its
  dependency libraries), and `default.nix` deploys the *union* of every
  registered instance's resolved components into one shared, deduped
  `PrismLauncher/libraries/` `xdg.dataFile` tree — verified end-to-end,
  69 real files including a hash-verified 23MB
  `com/mojang/minecraft/1.20.1/minecraft-1.20.1-client.jar`.
- Researched (not implemented, out of scope): PrismLauncher's own
  account/auth (`accounts.json`, MSA/Microsoft OAuth) cannot be reused
  from the vanilla-launcher module (`games/Minecraft.nix`, a different
  legacy-Mojang-token system entirely) and cannot be non-interactively
  provisioned by Nix at all — needs a real interactive login through
  PrismLauncher itself, confirmed via its own account/auth docs.
