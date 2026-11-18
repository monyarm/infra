---
name: reference_dosbox_runtime_choice_for_dos_titles
description: "2026-11-17 findings: DOSBox Staging rejects CHD in principle, DOSBox-X mounts CHDs, pinned-nixpkgs DOSBox versions, chdman lives in pkgs.mame, GOG DOS releases unpack as a pre-installed dir so no image conversion is needed, and the repo-fitting compression route is a Nix-built squashfs/EROFS image mounted at launch"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T23:36:33.588Z
---

Research answered 2026-11-17 on which DOSBox to use for the remaining owned DOS titles (the two Call of Cthulhu adventures, Stargunner, the SSI Gold Box collections).

**CHD is not the deciding axis.** DOSBox Staging has no CHD support and upstream argues it should never get it (dosbox-staging issue #166): DOS games `fopen`/`fread`/`fseek` plain files rather than reading a block device, so CHD's sector-level compression does not map onto them. What Staging added in 0.83/0.84-dev is floppy/CD automounting (floppy images recognised by geometry), UTF-8 filename conversion and CHCP. Its bundled "ROM package" format (issue #1262) is still only a proposal. DOSBox-X is the one with CHD — added in 0.83.8 via libchdr; `IMGMOUNT` takes MAME CHDs, and it also mounts zip/7z directly and emulates 8086 → Pentium/PC-98.

**Compression options, if one compressed artifact is wanted at all** (asked again 2026-11-17):
- CHD under DOSBox-X only — ties the title to X instead of Staging.
- **SquashFS or EROFS image built in Nix and mounted read-only at launch** — the only route that fits this repo: DOSBox still sees a plain directory, so no runtime/emulator support is needed. Shape would be a `buildDosBox`-style helper that squashes the data derivation and mounts it before exec.
- Nothing — data already comes from `fetchGOG`/`fetchSteam` decompressed in the store and Nix dedups it; compression only shrinks a single carryable artifact, it does not make the game faster.

**Pinned nixpkgs (2026-11-17):** `dosbox` 0.74-3, `dosbox-staging` 0.82.2 (upstream 0.83.1 → lags; override src via `sources.dosbox.toml` + `fetchGitTree`), `dosbox-x` 2026.10.01 (far ahead of the 0.83.8 CHD cut). `dosbox-pure` is not packaged in nixpkgs. There is no standalone `chdman` attribute — it comes from `pkgs.mame`.

**GOG DOS releases unpack to a pre-installed game directory plus a `dosbox*.conf`**, and the repo's `fetchGOG` already strips the Galaxy/DOSBox cruft — so for most of these titles there is no disk image to convert at all: mount the unpacked dir as `C:` and run the game's own `.bat`/`.exe`. Only convert with `chdman` if a single compressed artifact is actually wanted, and then the launcher must be DOSBox-X.

**Per-title shape:**
- Call of Cthulhu: Shadow of the Comet / Prisoner of Ice — dir mount; need per-game sound (AdLib/GM vs PC speaker) and speed config.
- Stargunner — 320×200 VGA, single exe, dir mount; only `cycles`/`machine` tuning.
- SSI Gold Box collections (FR Archives 1–3, Ravenloft, Dark Sun, Krynn, Al-Qadim, Silver Box) — each collection ships its own `.bat` launcher menu with every title in its own subdirectory: one derivation per collection plus a wrapper that `cd`s into the chosen title dir and runs the collection menu (or a generated `GAME.BAT`). They are CGA/EGA and CPU-speed sensitive, the main candidates for DOSBox-X's finer machine settings.

**Why:** this decided the runtime per title and killed the "convert everything to CHD" idea before it reached a design.
**How to apply:** default to `dosbox-staging` (best audio/CRT handling, automounting, iso/cue/bin mounts) for dir mounts; reach for `dosbox-x` for early 8086/EGA titles, odd CD/archive images, or CHD. Skip `dosbox` 0.74-3. Also `Dosbox.nix` still carries a 0.78.1-era config and needs a refresh when the first title lands.
