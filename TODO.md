# TODO

## Add ZM Desktop Elf wallpapers

Steam metadata:

- App ID: `3003300`
- Depot ID: `3003301`
- Manifest ID: `687685243173997847`
- Selected files:
  `bin/Skin/wallpaper/sourceImage/{06,07,08,09,10,11,12}.png`
- Use `fetchSteam` with `filelist` restricted to those seven files.
- Requires a newer DepotDownloader before the depot can be prefetched and its
  fixed-output hash recorded.

## Fix `<nixpkgs>` system registry pin

`nix registry list` shows `system flake:nixpkgs path:/nix/store/2gi66ywhbj66ssbz5bhgibzafa15m7zy-source`
overriding the `global` entries -- resolves to a stale 24.11-era nixpkgs
(confirmed missing `lib.sources.urlToName`, which real/current nixpkgs has).
Any ad-hoc `nix eval`/`nix build --expr` using `<nixpkgs>` (not this flake's
own pinned input) silently gets that old tree. Worked around in
`update-sources.py` via `nixpkgs_import_expr()` (resolves through
`builtins.getFlake "git+file://..."` instead), but the stale system pin
itself is still there and will bite anything else that reaches for
`<nixpkgs>` on this machine.

## Dynamic derivations for npm/pnpm/cargo/go dep-hash pinning

Every `npmDepsHash`/`pnpmDeps.hash`/`cargoHash`/`vendorHash` in this repo
(e.g. `packages/caveman-cli.nix`'s `pnpmDeps.hash`) is a plain hand-pinned
FOD hash today -- same as any nixpkgs package, refreshed by rebuilding with
`lib.fakeHash` and copying the mismatch. Worth revisiting with the same
`recursive-nix`/`dynamic-derivations`/`builtins.outputOf` mechanism
`lib/optimize/dynamic.nix` already uses: an outer derivation actually runs
the real fetch (`pnpm install`/`npm install`/`cargo fetch`/etc, needs real
network -- unlike `dynamic.nix`'s offline inner step), measures the
resulting store hash itself, `nix-instantiate`s a `fetchPnpmDeps {... hash = <measured>;}`-shaped expression, and chains onto it via
`builtins.outputOf` -- self-resolving on every build, no manual
fakeHash-and-paste step whenever a HEAD-pinned source moves.

Not started: this is genuinely new infrastructure, not a copy of the
existing pattern -- `dynamic.nix`'s outer step gets to skip network/trust
concerns entirely because wadptr/rpatool/minijson are pre-built ambient
inputs, not fetched inside it. This one fundamentally can't.

## Convert media handlers (png.nix et al) from mkDerivation to primitive derivation

`lib/optimize/handlers/png.nix` (and the other media handlers: webp/jpeg/
gif/ico/tga/mp3/ogg/wma/wav/flac/swf/obj -- anything using `pkgs.runCommand`)
still goes through nixpkgs' full `stdenv.mkDerivation` construction machinery
per stage (`assertValidity`/`mapAttrs`/`optionalAttrs`/etc), confirmed via
eval-profiler flamegraph as real, non-trivial eval-time overhead (~11-15% of
a real archive's eval, e.g. `assertValidity`/`elemAt`/`mapAttrs` frames in
`make-derivation.nix`). `guardSize`/`passthroughCopy`/`dynamic-inner.nix`'s
own final assembly step already proved the primitive-`derivation {}` pattern
works and is much cheaper to construct (see this session's dispatch-batching
work).

**Don't just convert the recipes wholesale** -- that changes every stage's
derivation hash, forcing every already-optimized archive's PNGs/media to
rebuild from scratch (real, expensive recompression work across every
archive in the registry, unlike the cheap copy-only conversions already
done). Converting is only worth doing once there's a way to **seed the new
primitive derivations' outputs with the existing mkDerivation-based
outputs' already-computed content** -- the *shape* of the derivation
changes (primitive vs stdenv-based), but the actual build-phase *logic*
(same oxipng/optipng/advpng invocations, same flags) stays identical, so
the output bytes should be byte-identical too. If the output can be
seeded/pre-populated under the new derivation's own computed hash (these
are all `__contentAddressed` already), Nix would recognize it as already
built and skip re-running oxipng/etc entirely, rather than needing a real
rebuild. Needs figuring out the actual seeding mechanism (e.g. building
under the old recipe once, then `nix-store --add`/registering that output
under the new CA derivation's hash) before doing the conversion for real.

## DONE: optimize pipeline moved to build-time dynamic derivations

Archive/pk3 optimize (`extractOptimizeRepack`) no longer fans out per-member
work at eval time -- eval only ever sees one folder-derivation in, one
folder-derivation out (`lib/optimize/dynamic.nix`), regardless of archive
size. The generator (a primitive `derivation {}`, never
`stdenvNoCC.mkDerivation` -- that distinction is what made this work at all,
see gotchas below) walks the real extracted folder at *build* time,
individually `nix-store --add`s each file (content-addressed by basename +
bytes alone, so an unchanged file survives an archive update at the same
store path and skips reprocessing entirely), and constructs a real raw-JSON
derivation graph (`nix derivation add`) so Nix's own scheduler parallelizes
independent per-file builds across remote builders -- not a sequential
shell loop. `lib/optimize/dynamic-inner.nix` runs each file's actual
optimize handler inside that generator via a fresh `nix-instantiate`.

Gotchas worth remembering if this ever needs touching again:

- Every derivation in the chain must be primitive `derivation {...}`, never
  `stdenvNoCC.mkDerivation` -- using stdenv anywhere in a dynamic-derivation
  chain (producer or a wrapper consuming its `builtins.outputOf` result)
  reliably reproduces `error: derivation has incorrect output` on this Nix
  version, confirmed via nix's own functional test suite as the reference
  shape.
- `nix derivation add`'s JSON schema is nix-version-dependent (nested
  `inputs.drvs`/`inputs.srcs` on Determinate/2.34.8 vs top-level
  `inputDrvs`/`inputSrcs` on stock 2.31.5) -- pin `pkgs.nix` to
  Determinate Nix wherever this runs.
- Raw-JSON derivations get no automatic `PATH` -- every tool invocation in
  a hand-written builder script needs its full store path spelled out.
- `inputs.srcs` entries must be basenames, not full store paths.
- `builtins.outputOf` needs `builtins.storePath "/nix/store/..."` (real
  string context) plus `--impure`.
- Chaining two `builtins.outputOf` calls in one Nix expression
  (`outputOf (outputOf x "a") "b"`) hits a real, reproducible Nix
  limitation -- sidestepped by having the generator's own build script do
  the two-step CLI resolution (`nix build "$drv^out"`) internally instead.
- `echo "$var" | nix derivation add` corrupts multi-line JSON in this shell
  (interprets `\n` as a literal newline even without `-e`) -- use
  `printf '%s'` for anything piped into `jq`/`nix derivation add`.

Separately-pinned `optimize-nixpkgs` (not following the main flake's
nixpkgs) so a tool version bump doesn't force re-deriving every
already-optimized file; content-addressing (`__contentAddressed = true`)
stacks on top for a second dedup axis (byte-identical output despite a
changed recipe hash still skips the rebuild).

## DONE: eval-time hot-path fixes + wasm ports

Full `nixosConfigurations.gaming-laptop` eval: **~45-48s baseline -> ~34.6s**
after all of the below. Confirmed via `NIX_SHOW_STATS` and a full-eval
`--option trace-function-calls true` run (15,530,063 total function calls)
that our own repo's code is **0.6% of total calls**, nothing else registers
as a hot spot -- conclusive, nothing further to chase here.

Fixes, in order of impact:

- **Wallpapers routed through the dynamic-derivations path** (biggest
  single fix): `hosts/home/monyarm/config/Backgrounds/default.nix` used to
  `map optimize'` over ~1600 individual wallpapers directly at eval time,
  each paying the full dispatch/sort/rename machinery -- ~20% of total
  eval-profiler samples on its own. Now assembles the raw files into one
  flat pool folder first, then a single `optimizeFolderDynamic` call.
- **`extractOptimizeRepack` no longer iterates archive members at eval
  time** -- dropped-extension filtering and the unhandled-extension warning
  moved into `dynamic.nix`'s build-time file walk; the eval-time copy was
  pure redundant cost (`dynamic-inner.nix` already emits the same warning
  at build time).
- **`resolveExt`'s dispatch-map sort actually memoized** (took two passes
  to get right -- a first fix only memoized *building* the map, not the
  sort inside `resolveExt` itself, which still re-ran every call regardless
  of whether the map was shared; a sampling flamegraph's before/after
  sample-count drop made it *look* fixed when it wasn't -- caught by
  `--option trace-function-calls true`'s exact call counts instead).
  `lib/misc.nix` now splits `sortDispatchKeys`/`resolveExtSorted`/
  `dispatchExtSorted` out from the re-sort-every-call convenience wrappers.
- **`sanitizeName`** (`lib/strings.nix`): `builtins.elem` linear scan ->
  attrset lookup, ~2.5x faster per call. Its eval-time significance mostly
  came from the per-archive-member fix above, though -- this alone wasn't
  the big win.
- **`flake.nix`'s `packages` output**: `filterAttrs (isDerivation)` forced
  *every* package's full construction (Nix's `derivation {}` isn't lazy
  per-attribute -- checking `.type` costs the same as building the whole
  thing) on every eval touching any flake output, not just `packages`.
  Switched to a name-based denylist (`nonDerivationPackageNames`, empty
  today) -- same safety net (a real mistake still fails loudly via
  `nix build`/`nix flake check`), zero forcing cost.

**Wasm** (`lib/wasm.nix` + `lib/wasm/math` + `lib/wasm/serialize`, using
`DeterminateSystems/nix-wasm-rust` as a flake input): `crc32` (was
`shortcuts.vdf.nix`'s hand-rolled bit-twiddling), `toKeyValues` and
`toSexpr` (was a Python `json-sexpr` subprocess + forced eval-time
`readFile` IFD -- that whole chain is gone now) all ported, verified
byte-identical against their originals. Notes worth keeping if extending
this:

- Target `wasm32-unknown-unknown`, not `wasm32-wasip1` -- none of these
  candidates need OS/filesystem access, and unlike `wasm32-wasip1` (needs
  real WASI-sysroot cross-compilation machinery), `wasm32-unknown-unknown`'s
  std is bundled directly in nixpkgs' plain `pkgs.rustc`.
- Build via plain `pkgs.cargo`/`pkgs.rustc` + `pkgs.lld`'s `wasm-ld`
  directly (`RUSTFLAGS = "-C linker-flavor=wasm-ld -C linker=wasm-ld -C link-arg=--allow-undefined"`) -- `pkgsCross.wasi32.rustPlatform` hits an
  unresolved linker-flavor bug, don't bother with it for this shape of
  candidate.
- `wasm-builtin` is in `lib/nixSettings.nix`'s real nix.conf source now, but
  needs an actual switch to land on this machine's live nix.conf --
  `flake.nix`'s `nixConfig.extra-experimental-features` delta covers
  evaluating this flake before that switch (needs `--accept-flake-config`),
  but `--accept-flake-config` does *not* non-interactively persist trust
  for a brand-new experimental-features value the way it does for
  substituters -- may need `--extra-experimental-features wasm-builtin`
  explicitly until the switch happens.
- A cross-call cache was considered and explicitly **not** built: measured
  ~7ms/call, real call volumes are dozens not thousands, and none of these
  candidates' real call sites ever compute the same input twice in one eval
  -- nothing for a cache to hit, and Nix has no value-keyed memoization
  across independent thunks to build one cheaply anyway.
- Grouped by domain (`math` for numeric/bitwise, `serialize` for
  attrset/list-shaped output) -- add new candidates to one of these two
  modules rather than a new module each, unless the shape genuinely differs.

**Not pursuing right now** (explicit decision, not forgotten): the
text-transform candidates (`removeBlankLines`/`removeLineComments`,
`removeBlockComments`, `obj-lossless.awk`, `modstrip.py`, `objmin.js`,
`glslmin.js`) are real, viable wasm candidates now that `dynamic-inner.nix`
runs after files are already realized on disk (no IFD concern), with a
clear porting shape (`readFile` -> wasm -> `builtins.toFile` -> the
existing `isDerivation` fallback in `dynamic-inner.nix`) -- just not
scheduled. `toRCFile` (`lib/format.nix`) has the same zero-call-sites shape
`toSexpr` used to, not worth porting for the same reason. A broader repo
survey (`bitAnd`/`bitOr`/`bitXor`, `foldl'`, recursive-attrset walkers)
turned up nothing else.

## Investigate free cloud providers for additional Nix remote builders

Look into Oracle Cloud Always Free and nixbuild.net (and anything else
relevant) as ways to add build capacity without spending anything, to reduce
reliance on the single existing `ssh://monyarm@monyarm` remote builder.

### Research findings (as of July 2026)

**Oracle Cloud "Always Free"** — genuinely perpetual, not a time-limited trial.
Two separate free compute pools, can run simultaneously:

- **Ampere A1 (ARM/aarch64)**: recently cut from 4 OCPU/24GB to **2 OCPU/12GB**
  total (change made quietly, effective June 15, 2026, no announcement — found
  out from community reports, not Oracle's own comms). Can be split across up
  to 4 VM instances. Monthly allowance: 1,500 OCPU-hours / 9,000 GB-hours.
  Since the actual builds here are `x86_64-linux`, an ARM builder would need
  QEMU/binfmt emulation to build x86_64 derivations — works, but slower than
  native.
- **AMD Micro (x86_64)**: up to 2x `VM.Standard.E2.1.Micro` instances, 1 OCPU /
  1GB RAM each, genuinely x86 — no emulation needed, but small (1GB RAM is
  tight for real compression work like 7z-packing a big pk3). Confirmed still
  available and unchanged by the June 2026 ARM cut.
- Combined theoretical free capacity: \*\*2 native x86_64 OCPUs (2GB RAM total)
  - 2 ARM OCPUs (12GB RAM, needs emulation for x86_64 builds)\*\*.

**nixbuild.net** — not a perpetual free tier, but a real recurring one: **25
free CPU-hours every month**, on both x86-64 and ARM, no VM setup/maintenance
at all — it's Nix-builds-as-a-service, so integration is just pointing
`/etc/nix/machines`-equivalent config at their endpoint. Paid rate beyond the
free allowance is €0.12/CPU-hour. Lowest-friction option of everything here
since there's no server to provision or keep alive.

**Google Cloud "Always Free"** — 1x `e2-micro` instance, genuinely perpetual
(not the separate 90-day/$300 GCP trial credit), x86_64, but very small
(0.25 vCPU shared-core, 1GB RAM, specific US regions only). Limited value on
its own, could add a little extra parallelism.

**AWS** — ruled out. No real permanent free tier for EC2 anymore for accounts
created after July 15, 2025 (only a 6-month, $200-credit trial now). Legacy
accounts from before that date still get 750 hrs/month of t2/t3.micro, but
only for their first 12 months, not forever. Not a genuinely free-forever
option the way Oracle/GCP/nixbuild.net are.

### Smaller / specialized / niche options

**Garnix** — a Nix-specific CI service. Free tier includes real CI minutes and
(per their docs) "2 months of a 4GB RAM/2 vCPU server", which reads more like
a trial than perpetual free compute. They're explicitly generous for genuine
open-source projects (more CI minutes on request, free hosting, even revenue
sharing if your software gets deployed on their infra by others) — but that
generosity is aimed at public open-source projects soliciting outside use,
not a private personal dotfiles repo, so the practical value here is unclear
without actually asking them.

**GitHub Actions as an ephemeral remote builder (the "trick")** — this is a
real, established pattern, not a hack nobody's tried: tools like
`joshlarsen/ssh-tunnel-action` (ngrok-based) and `nix-remote-builder-aws`
(same idea, AWS-backed) show the shape — a workflow run installs Nix, opens an
SSH tunnel out (ngrok or similar) from the ephemeral runner, and your own
local `nix` adds that tunnel's address as a temporary entry in its builders
list for the life of the job. Real constraints: the runner disappears when the
job ends (GitHub's max job runtime, and you'd need to actually orchestrate
"start workflow, wait for tunnel to come up, add it as a builder, dispatch
work, tear down" — nothing does that end-to-end for you), so this is burst
capacity for a one-off big job, not a standing builder.

- Confirmed directly: standard GitHub-hosted Linux/Windows/macOS runners are
  **free and unlimited** for public repositories, on every plan including
  Free — no practical minute cap for an honest use pattern. Private repos
  are capped at 2,000 Linux minutes/month on the Free plan.
- The actual trick, then: since this config repo is presumably private
  (it manages secrets via sops-nix), don't use it directly — spin up a
  separate, minimal, throwaway **public** repo whose only job is "install
  Nix, open a tunnel, idle" and trigger it on demand. That repo contains
  nothing sensitive, and unlocks the genuinely-unlimited public-repo minute
  policy instead of being capped at 2,000 min/month.

**Cachix** — not a builder at all, it's a binary cache (10GB free tier). Worth
pairing with any of the above (or the existing setup) so repeated builds of
unchanged content don't need re-dispatching anywhere, but it doesn't add
compute capacity by itself.

**sourcehut (builds.sr.ht)** — ruled out. Checked directly: no free tier for
the CI/build service at all, paid-only starting at €4/month.

**Fly.io** — ruled out for new use. Free tier was discontinued for new
signups in 2024 (now just a 7-day/2-VM-hour trial). Only accounts that were
already on the old Hobby plan before the cutoff still get 3 free small VMs —
not something newly available.

**Scaleway / IBM Cloud** — checked, found no equivalent to Oracle/GCP's
perpetual always-free VM tier. IBM Cloud has a handful of always-free
*services* (mostly Watson APIs, not general compute); Scaleway appears to be
pure pay-as-you-go with no free compute allowance. Not worth pursuing further
unless something more specific turns up.

**The actually-simplest option: existing spare hardware.** Given the whole
existing `ssh://monyarm@monyarm` builder setup is already understood in
detail (this session spent a lot of effort on exactly that), the lowest-risk
way to add capacity is genuinely free — any spare machine already on the LAN,
even something small like a Raspberry Pi, added as one more entry in
`/etc/nix/machines`. No account, no quota, no emulation question if it's
x86_64 already. Worth remembering this is on the table before chasing more
cloud-provider free tiers.

### Theoretical extra free job-slot capacity, roughly

- Oracle: ~2 extra native x86_64 job slots (tiny, 1GB RAM each) + ~2 extra ARM
  job slots (12GB RAM total, needs emulation) — free forever.
- GCP: ~1 extra tiny x86_64 job slot — free forever.
- nixbuild.net: effectively "as many parallel jobs as fit in 25 CPU-hours,
  refreshed every month" — a real but capped recurring allowance, not
  permanent extra capacity like the VM options.
- GitHub Actions (via a throwaway public repo): effectively unlimited
  *burst* capacity on standard runners (2 vCPU / 7GB RAM per job as of
  current GitHub-hosted Linux runner specs), but only for the duration of a
  single workflow run and only with real orchestration work to wire the
  tunnel up as a usable builder — not standing capacity like the others.
- Spare LAN hardware: whatever you actually have sitting around, free of
  quota/account/emulation concerns entirely.
- Garnix: unclear value for a private repo; would need to actually ask them
  rather than assume.

Worth prioritizing nixbuild.net first (lowest setup effort, genuinely useful
recurring allowance), spare hardware second (zero ongoing friction if
anything's available), and Oracle's x86 micros third (native architecture, no
emulation) if actually pursuing this — the ARM allocation is the most compute
on paper but the emulation overhead for `x86_64-linux` builds needs testing
before counting on it for anything real. GitHub Actions tunneling is the most
interesting "free" number on paper (unlimited public-repo minutes) but also
the most engineering effort for the least reliable result — worth treating as
a last resort for occasional burst jobs, not infrastructure to depend on.

## Scope .envrc's rerun trigger to the shell + secrets, not every tracked file

Right now editing an unrelated ancillary file (a wad entry, `lib/optimize/*`,
anything content-wise disconnected from the devShell or secrets) still
triggers a rerun/reload, which is expensive given how much this flake
evaluates (see the eval-performance and dynamic-derivations sections above).
It should only rerun when something that actually changes the shell
environment or secrets changes: `flake.nix`/`flake.lock`, and
`secrets/env.json` (already explicitly `watch_file`'d for the sops-decrypt
step).

Not yet researched: the exact mechanism causing the over-broad reruns --
whether it's nix-direnv's own cache-invalidation (`use flake .`, which
should in principle only watch `flake.nix`/`flake.lock` by default) actually
watching more than that here, or whether it's flake-parts' `imports = [ ./hosts ]` forcing evaluation (and thus git-tree-dependence) of the entire
module tree even when only the small fixed `devShells.default` is requested.

## Disc ripping: fetcher variants, drive system-features, DAT-identified dynamic derivations

Route physical disc ripping through the same build-lock machinery
(`/build-locks/cdrom.lock`, alongside `dynamic-optimize.lock` -- see
`lib/optimize/dynamic.nix`) -- only one disc can be read at a time
regardless of which rip strategy handles it.

- Gate ripping derivations on drive presence via Nix's own
  `buildMachines.*.supportedFeatures` / `requiredSystemFeatures` mechanism
  (already used for `kvm`/`big-parallel`/etc, see
  `hosts/modules/base/default.nix:21`), not a bespoke `mkOption` boolean --
  a `"disk-drive"` feature declared on hosts that physically have one, so
  Nix's own scheduler routes/refuses ripping derivations correctly instead
  of failing at build time against a missing device.
- `redumper` needs its own, stricter feature (e.g. `"redumper-drive"`) --
  it's picky about which drive models support the raw C2/subchannel reads
  it needs, so "has *a* disk drive" isn't sufficient for redumper jobs
  specifically.
- Fetchers are per-rip-strategy variants, same shape as the existing
  `lib/fetchers/*.nix` (fetchGog/fetchSteam/fetchItch/...): PC software
  copies the disc's contents straight to `$out`; PS2 does whatever the
  existing `~/local/dvdrip` workflow already does (see
  `hosts/modules/config/doas.nix:11`'s passwordless-doas grant to it -- not
  the `dvd::rip` GUI package); PS1 and other formats needing accurate
  dumping go through `redumper`.
- Idea: identify the ripped disc via a DAT file (redump.org-style hash ->
  title database) at *build* time (the disc's identity isn't knowable at
  eval time, only after it's actually read) and rename the resulting
  derivation accordingly -- same build-time-dynamic-derivation shape as
  `lib/optimize/dynamic.nix`'s `instantiateDrv`/`builtins.outputOf`
  pattern, applied to naming instead of per-file optimization.
  Needs to be pinned down before a fix can be scoped correctly.
