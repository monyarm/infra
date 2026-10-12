# PSP Console Research

Findings split into **verified** (read from a pinned source or confirmed by a
build in this repository) and **unverified** (assumed, or read from an
unpinned/archived source). Unverified items must not be implemented: the
console modules fail closed per feature until each is verified.

## Verified

### Categories Lite directory conventions

Source: the plugin's own source, `codestation/gclite` (`category.c`,
`gcread.c`, `vshitem.c`, `config.c`), which is the upstream of the
"Game Categories Lite" forks. Confirmed by reading the code, not a wiki.

- Categories are **directories** directly under `/PSP/GAME` and `/ISO`. A
  resource's category is therefore a single string, never a list, and there is
  no separate membership structure.
- With the prefix option enabled, only directories whose names start with
  `CAT_` are treated as categories, and the prefix is stripped for display
  (`sce_paf_private_strncpy(dir.d_name, dir.d_name + 4, ...)`).
- With the prefix disabled, a directory counts as a category when it is not
  itself a game folder and contains at least one subdirectory.
- A directory is a game folder when it directly contains `EBOOT.PBP`,
  `PARAM.PBP`, or `PBOOT.PBP` (`eboot_types[]` in `category.c`).
- Version 1.6 adds optional sorting: `CAT_XX<name>` or `XX<name>` with `XX`
  between 00 and 99.
- Limits: at most **8** categories including the synthetic "uncategorized"
  entry, and the category folder name plus the homebrew folder name together
  may not exceed **30** characters, counting non-ASCII characters as two.
- `gclite_filter.txt` in `SEPLUGINS/` hides listed folders; one name per line,
  and the file must end with a newline.
- The plugin must be the **first** entry so it loads before other VSH plugins.
- **Not declarable:** the plugin's own settings (mode, prefix, uncategorized,
  sort) are stored as a raw binary `CategoryConfig` struct at
  `ms0:/seplugins/gclite.bin`, written by its System Settings menu. That is not
  a text format and is not reproduced from Nix. The `prefix` and `sort` options
  in this flake must be set to match the device's System Settings selection.

### PSP plugin binaries

Pinned sources. Hashes were verified by downloading each payload and checking
it is an ELF PRX (`7f 45 4c 46`). All are release binaries rather than git
checkouts, so they are fetched by URL rather than through the `sources.toml` /
`fetchGitTree` pipeline.

| Plugin | Version | Source | sha256 (SRI) |
|---|---|---|---|
| Categories Lite | 1.6 | `codestation/gclite` release zip, member `category_lite.prx` | `sha256-w7baoGUj5tFxQOA2fJHZbINa/Du9J5L1fes7a0fd2FI=` |
| missyhud | 0.7 | `pebeto/missyhud.prx` release asset | `sha256-YCiSuGCqTg6HrZ2t+sgupgufm6IuMMxW4L31h5e0H1M=` |
| KillSwitch | 1.3.0 | `crozone/PSP-KillSwitch` release asset | `sha256-OW6mLo7GobpXopumXdFV+TuHQEidZ3PAF9AVYdSxtBs=` |
| cxmb | 1.2.1 | `cello0314/CXMB` release asset | `sha256-97mnBd98ClJ6fjcDrdqO97pPVjaXnF8Juto6odiIX/o=` |
| cwcheat | 0.2.3 | gamebrew `cwcheat6xx.7z` | `sha256-FxThew4jhdi0zGYTDzqV5aivs43RM57YYfjr8ylyPSk=` |
| cwcheat-pops | 0.2.3 | gamebrew `cwcheatbundle.7z` | `sha256-QM2+MrQraBcn9UER2ykEtD53s8g/2K88h8pfoY2DbIY=` |

Runlevels come from each plugin's own README, not from guesswork:

- Categories Lite — `vsh`, and its readme requires it to be the **first**
  plugin listed, so the registry pins it to a negative `order`.
- missyhud — `game`. KillSwitch — `game`. cwcheat — `game`;
  cwcheat-pops — `pops` (its own README documents the pops build).

**cxmb provenance.** `cello0314/CXMB` is the only fork of `PSP-Archive/CXMB`
and the only one publishing a binary. It fixes an Adrenaline coldboot hang and
a PSN EBOOT issue, and targets 6.61 CFW. It is *fresh*, not *proven*: 5 stars,
one maintainer, both commits on one day. Flagged rather than presented as
established.

**cwcheat has no maintained fork.** The project predates GitHub and lives on
wikis/forums; the GitHub hits are cheat *databases*, not the plugin. So it is
sourced from gamebrew.org's archive instead. `cwcheat6xx.7z` holds the 6.60
build, which is the one that runs on modern CFW.

### gamebrew.org fetching

gamebrew hosts binaries itself and refuses them unless the request carries a
`Referer:` naming the wiki page; without it the response is a 403 HTML
interstitial rather than the file. `lib/fetchers/gamebrew.nix` reproduces that:
it reads the page, picks a download by filename, and curls it with the referer.
The `?k33p0fil35` query on some links is a stable cache key, not a per-request
nonce — repeated fetches are byte-identical — so a pinned hash stays valid.

Note that the `file` selector must be resolved at Nix level, not in the shell:
it is a Nix argument, so a runtime `[ -n "$file" ]` test would always see it
empty and silently fall back to the first link on the page.

### devkitPSP in Nixpkgs — the toolchain question, answered

**Verified: a generic MIPS cross-compiler cannot build PSP homebrew.** Not a
matter of effort:

- The target triple is literally `psp`, not `mipsel-*`
  (`psp-gcc` configures `--target=psp`).
- The ELF emulation is binutils' `elf_mipsallegrexel_psp`, not upstream
  `elf32elmip`.
- The linker script needs `OUTPUT_ARCH(mips:allegrex)` and defines sections
  that exist in no generic MIPS ABI: `.sceStub.text`, `.lib.ent`, `.lib.stub`,
  `.rodata.sceNid`.
- Every firmware call is a **SHA1-derived NID stub**: `pspimport.s` emits a
  `.sceStub.text` entry plus a matching `.rodata.sceNid` word per imported
  `sceIo*` function. Stock newlib has no concept of this.

**Verified: devkitPro no longer ships PSP at all.** `devkitPro/pacman-packages`
contains zero PSP paths; the `devkitpro-ppsdk` / `devkitpro-psp-dev` package
names are dead. devkitPro's installer releases stop in 2018 and publish no
Linux tarball. So option (c), "use devkitPro's prebuilt SDK", does not exist.

**Verified: the live toolchain is pspdev's, and it is Nix-ready.** The build is
a standard binutils -> gcc(C-only, `--without-newlib`) -> newlib -> gcc(full)
bootstrap, and stage-1 needs only host gcc plus stage-0 `psp-as`/`psp-ld`, so
no cross-of-a-cross bootstrap is required. `pspdev/pspdev-nix` is the
upstream's own flake for exactly this and publishes a public binary cache at
`pspdev.cachix.org`, so the GCC 15.2.0 build is usually substituted rather than
compiled. pspdev also ships monthly full SDK tarballs
(`pspdev-ubuntu-latest-x86_64.tar.gz`, ~165 MB).

So the correct answer to "can we make do with just a cross-compiler and some
libraries?" is: **no for a generic toolchain, yes for pspdev's, and it should
be consumed as a flake input rather than rebuilt by hand.**

#### Two pspdev-nix traps (both verified, both bite hard)

1. **psp-newlib fetches by *branch name*, not sha.** `nix/packages/toolchain/ psp-newlib.nix` does `rev = version` where `version = "allegrex-v4.5.0"` —
   that is a `refs/heads/` name, not a tag. When the branch moves, the recorded
   `hash` silently stops matching and the toolchain fails with a fixed-output
   mismatch. Every other toolchain source pins a real sha (e.g. gcc-bootstrap's
   `1a33997...`), so newlib is the odd one out. The fix is an override pinning
   the sha; see `hosts/console/psp/scope.nix`.

1. **An overlay of `psp-newlib` is silently bypassed.** `nix/packages/default.nix`
   builds its callPackage scope as `pkgs // packages`, and
   `toolchain/default.nix` instantiates `psp-newlib` through that scope. Because
   `packages` wins over `pkgs`, *any* `psp-newlib` overlay is ignored for the
   whole chain (pthread → pspsdk → sysroot → gcc). You must recompute their
   scope, not overlay it — which is exactly what `scope.nix` does. Confirmed by
   the override's `drvPath` propagating only once the scope is reimplemented.

Traps 1 and 2 stack: the branch drift is unfixable by an overlay (trap 2), so
you need the scope rewrite anyway. Do that first.

**Verified: maintained homebrew builds unmodified.** `pspMkDerivation` builds
real third-party projects from a plain `include $(PSPSDK)/lib/build.mak`
Makefile with no patching: `violinmelody/2048PSP` (MIT, multi-file game using
pspgu/pspaudio/psprtc + an icon asset) and the pspdev `gu/cube` 3D sample both
produce valid `EBOOT.PBP` (magic `\0PBP`, SFO `\0PSF`, data.psp a MIPS ELF).
Stale homebrew predating the current SDK may not: `sixf0ur/llama2psp` (MIT)
fails to link with a duplicate `__udivdi3` because its old `libcglue.a` and GCC
15's libgcc now both define it — a toolchain-age issue in the project, not a
toolchain bug. A homebrew source build needs the SDK's `PSP_MODULE_INFO`
module-info section or `psp-fixup-imports` rejects the ELF.

### ARK-5 settings and plugins

Source: the ARK-5 source (`PSP-Arkfive/ARK-5`, `SystemControl/src/`,
`XMBControl/src/`) and the `psp-cfw-sdk` headers. ARK-4 is archived and
redirects here, so ARK-4 formats are historical only.

- `SETTINGS.TXT` lives at `<arkPath>/SETTINGS.TXT`, where `arkPath` defaults to
  `ms0:/PSP/SAVEDATA/ARK_01234/` (`DEFAULT_ARK_PATH`), falling back to flash1.
- `PLUGINS.TXT` lives at `ms0:/SEPLUGINS/PLUGINS.TXT` (and the `ef0` equivalent
  on PSP Go), and also at `<arkPath>/PLUGINS.TXT`.
- Both use CSV: `<runlevel>, <name-or-path>, <on|off>`. `,` is the delimiter.
  Comment lines start with `//`, `;`, or `#`. Empty lines are skipped.
- Boolean truth values are `on`, `true`, `1`, `enabled`; anything else is off.
- Runlevels: `always`/`all`, `game`, `umd`/`psp`, `homebrew`, `pops`/`psx`/
  `ps1`, `vsh`/`xmb`, `launcher`. A game ID or a path may also be used as the
  runlevel to scope an entry.
- Verified setting names: `usbcharge`, `wpa2`, `launcher`, `disablepause`,
  `oldplugin`, `noled`, `noumd`, `noanalog`, `hibblock`, `hidemac`, `hidedlc`,
  `deadef`, `vitamute`, `qaflags`, and the value-carrying forms
  `cpuclock:<133|222|333|383|403|423|443>`, `highmem[:auto|:force16|:forcemax]`,
  `mscache[:4k|:8k|:16k]`, `infernocache[:lru|:rr]`,
  `skiplogos[:gameboot|coldboot]`, `hidepics[:pic0|:pic1]`.
- ARK writes settings with `always`/`game`/`vsh` runlevels; simple device-wide
  settings use `always`.

### ARK-4 repository status

The `PSP-Archive/ARK-4` repository was archived on 2026-08-02 and redirects to
`PSP-Arkfive/ARK-5`. This flake targets **ARK-5**; the ARK-4 notes that were
here previously are superseded by the ARK-5 section above.

### Home Manager `home.file` semantics

Source: the pinned `home-manager` input,
`modules/lib/file-type.nix` and `modules/files.nix`.

- `source` is `types.path`, not a submodule with a custom merge.
- `text` synthesizes `source` via `pkgs.writeTextFile`.
- `recursive` is a plain bool, resolved at install time by `lndir`, not at
  evaluation time.
- `lndir` detects a regular file colliding with a recursively linked directory
  and fails or warns depending on `conflictType`. This is the precedent for
  doing collision detection at build/install time rather than eval time.

### Nix behaviour in this repository

Confirmed by build probes during Phase 1:

- `builtins.readDir dirDrv` on a derivation output **forces that derivation to
  build** (IFD). Directory expansion therefore cannot happen at evaluation
  time; it must happen inside the builder. This repository forbids IFD.
- A plain file placed in `nativeBuildInputs` breaks `runCommand`: stdenv setup
  attempts to execute it and the build fails with exit code 127. Data must be
  passed by string interpolation instead.
- `builtins.match` anchors the **whole** string. A "contains" test needs `.*`
  wrapped; POSIX classes such as `[[:cntrl:]]` are not supported.
- Nix has no `\xNN` string escape. `\x01` becomes the literal characters
  `x01`, which silently corrupts a character class. Control characters must be
  written with the real `\n`, `\r`, `\t` escapes.
- A `let ... in` body is an expression, not a statement list. Bare expressions
  and unparenthesized namespaced calls there are syntax errors; bind them and
  force with `builtins.deepSeq` when a guard must run eagerly.
- `lib.types.path` renders a derivation as its store path, but a `mkOptionType`
  defined with only `merge` and no `check` leaves values unnormalized and
  corrupts derivations.

## Unverified — do not implement yet

Each of these gates a later phase. They are recorded here so the blocker is
explicit rather than rediscovered mid-implementation.

### PSP asset formats and restrictions

**Partially verified.** The file *names* and *locations* are confirmed: for a
homebrew application, `ICON0.PNG`, `PIC1.PNG`, and `SND0.AT3` sit beside
`EBOOT.PBP` in the application directory, and disc images (ISO/CSO) carry their
metadata inside the image with no valid external override — declaring assets on
a disc image is rejected rather than silently ignored.

**Still not verified:** the exact accepted dimensions, colour depth, and size
restrictions for `ICON0.PNG`, `PIC0.PNG`, `PIC1.PNG`, `SND0.AT3`, and
`ICON1.PMF`. No serializer or dimension validator is written, because guessing
would produce files that merely look valid. Assets are copied byte-for-byte and
must be validated on real hardware.

### FAT32 allocation behaviour on a mounted card

Not verified on hardware. Cluster-size overhead means physical usage exceeds
logical size. Any capacity report must clearly distinguish exact measurements
from estimates, and needs real-hardware validation.

## Architectural decisions

- `consoleConfig.psp.<name>` is architecture-neutral in its public shape. Phase 1
  builders use a fixed `x86_64-linux` package set as a documented implementation
  detail; a per-system refinement can follow without changing the API.
- Logical `owner` is manifest attribution only. FAT32 has no POSIX ownership and
  none is implied.
- `.psp-nix/` is reserved for future deployment metadata.
- Collisions fail. Two declarations never silently overwrite each other.
- Directory sources expand regular files recursively; symlinks and special
  files are rejected.
- Resources (games, homebrew) are lowered into ordinary `psp.files` entries, so
  the deployment engine never learns about PSP content types.
- A resource's `category` is a single string; Categories Lite consumes it. There
  is no separate membership option.
- Metadata precedence is resource > resource-type default > global default >
  nothing generated. Assets for content types that cannot use them (disc
  images) are a configuration error, not a silent no-op.
- Categories Lite's plugin settings live in a binary blob on the card and are
  not managed; the flake only controls the directory layout and filter file.

## Real-hardware testing still required

Everything below can only be validated against a physical PSP or a mounted
card image, not by the automated test suite:

- That the generated tree is accepted by the PSP's filesystem.
- ARK boot behaviour with a generated `SETTINGS.TXT` / `PLUGINS.TXT`.
- Categories Lite rendering of a generated category layout.
- Icon, background, and BGM rendering by the XMB.
- FAT32 free-space and cluster behaviour under real deployment.
