# Disc-ripping fetcher infra + The Dig (ScummVM) example

## Context

TODO.md's "Disc ripping" section (`TODO.md:360-391`) is unimplemented infra.
Several GAME_IDEAS.md entries are owned as physical CDs/DVDs with no
`fetchGOG`/`fetchSteam` path: The Dig / Full Throttle / Sam & Max (ScummVM),
Jak 3 (OpenGOAL), StarCraft + Brood War (OpenBW), Unreal/UT99/UT2004
(OldUnreal). All of them need a build-time mechanism to read a physical
drive, exclusively, gated on host hardware -- matching the per-source
fetcher shape every other `lib/fetchers/*.nix` file already uses.

Per user steer this round:

- Build the infra **and** wire up one concrete example end-to-end, not just
  the infra in isolation.
- Implement all three rip angles from the TODO, but **do not** wrap the
  placeholder `~/local/dvdrip` script (`doas.nix:11`) -- it doesn't exist on
  disk, and PS2 discs are DVD-ROM data discs, not DVD-Video, so a
  movie-ripping tool doesn't apply anyway. Recreate the game-side
  extraction logic directly instead.
- DAT-driven hash lookup (redump.org databases) is back in, reshaped: not
  build-time identify-and-rename, but eval-time hash lookup by name via an
  IFD'd DAT-to-JSON derivation, feeding `ripDisc`/`ripDiscRedumper` their
  expected hash instead of the caller pinning it by hand.

Correction from user after first draft: PS2 discs do **not** get filesystem
extraction -- PS2 rips stay a raw whole-disc image (like a console dump),
only PC discs get their filesystem tree extracted to `$out`. So this stays
**three** fetchers: `ripDisc` (raw image), `ripDiscContents` (extracted
tree), `ripDiscRedumper` (accurate C2/subchannel dump). Also: redumper needs
more than a device path, and all three plausibly need root -- researched
below.

## Design

### 1. Build lock (`/build-locks/cdrom.lock`)

Same shape as `lib/optimize/dynamic.nix:317-322`'s `flockBlock` (only one
physical drive can be read at a time, regardless of which rip strategy runs).
Inlined as a local `let`-bound string in the new fetcher file -- it's 3
lines and only the second use of this exact pattern in the repo, not worth
extracting a shared helper yet.

```nix
flockBlock = ''
  if [ -d /build-locks ]; then
    exec 9>/build-locks/cdrom.lock
    flock 9
  fi
'';
```

### 2. System features (`hosts/modules/base/default.nix:21-28`)

- Reuse the existing `"cdrom"` feature already declared for the `monyarm`
  host (line 27) as the generic "has a disk drive" gate -- it's already
  sitting there unused by any derivation, evidently pre-declared for this.
  Don't introduce a redundant `"disk-drive"` name.
- Add `"redumper-drive"` next to it on the same host, as the TODO specifies:
  redumper is picky about drive models (C2/subchannel support), so it needs
  its own stricter gate separate from plain `"cdrom"`.

### 3. DAT database -- sources.toml fetch, DAT->JSON derivation, IFD load

User's idea, replacing the dropped "identify at build time and rename"
approach: redump.org DAT files list every known disc's expected hash(es) by
title. Load that as data, and have the disc fetchers look up their expected
hash by `name` instead of the caller pinning `sha256` by hand.

- **Source**: redump.org itself has no git repo; find a GitHub-hosted
  mirror of the specific console DAT files needed (PS1, PS2, ... --
  identify the right mirror at implementation time) and pin it via
  `sources.toml`'s `[git]` section + `fetchGitTree`, same as every other
  git-hosted source in this repo (`lib/fetchers.nix`'s `fetchGitTree`) --
  no new sources.toml section type needed for one consumer.
- **DAT -> JSON**: a small Python script (`py/dat-to-json.py`, same
  convention as `trim-lib.py`/`prune-handlers.py`) parses the Logiqx-XML
  DAT into JSON keyed by system, then title:
  - single-rom titles (most systems): `{ "<title>": { "sha1": "...", "size": N } }`
  - multi-rom titles (PS1-style cue/bin): `{ "<title>": { "tracks": [ { "name": "...", "sha1": "...", "size": N }, ... ] } }`
    This is a plain derivation (input is already hash-pinned via
    `fetchGitTree`, so the derivation is inherently reproducible without
    needing to itself be a FOD).
- **IFD load**: `builtins.fromJSON (builtins.readFile datJsonDrv)` at eval
  time in `lib/fetchers/disc.nix`. This is IFD (forces a build during
  eval) -- normally avoided in this repo (see the "no IFD" convention
  elsewhere in `lib/`), but explicitly accepted here since the DAT rarely
  changes and, once built once, the store path is just a cheap stat on
  every subsequent eval. Flag this as the one deliberate exception, not a
  precedent for other IFD use.

### 4. redumper CLI research (from `github.com/superg/redumper` README)

Confirmed `pkgs.redumper` exists in the pinned nixpkgs (`nix eval nixpkgs#redumper.pname` -> `"redumper"`). Real invocation needs more than a
device:

```
redumper disc --drive=/dev/sg1 --image-name=<title> --image-path=<dir> \
  --speed=8 --retries=100 [--dvd-raw for DVD/BD] [--overwrite]
```

- `--drive=` wants a **`/dev/sgN` SCSI generic device**, not `/dev/srN`.
- `--speed=`/`--retries=` have no universally-good default per the docs
  ("keep drive speed on the lower end, 8 is a good default") -- exposed as
  fetcher args with defaults, not hardcoded.
- **Disc must be unmounted first** -- the helper script does this before
  invoking redumper.
- Raw SCSI access on Linux effectively needs root in practice.
- README fetched is off `main`, not the exact commit nixpkgs has pinned --
  re-verify these flags against the pinned version's `--help` output at
  implementation time, don't trust `main`'s docs blindly.

### 5. Root requirement + disc-swap announcement -- one shared privileged helper

All three rip modes need root (raw `/dev/sgN` SCSI access for redumper;
raw block-device `dd` read + required unmount for the other two; PC-speaker
beep needs console/device access too). Rather than three separate doas
grants, **one store-built helper script**, parameterized by mode:

```
disc-rip-helper --mode=image|contents|redumper --title=<name> \
  --device=/dev/sr0 --out=<path> [--speed=N --retries=N --disc-type=T]
```

Responsibilities:

1. **Announce + wait for the right disc**: print `title` to the build log
   and beep via `pkgs.beep` (PC speaker) in a poll loop -- check every few
   seconds whether a disc is present (e.g. `blockdev --getsize64` succeeds /
   `blkid` on the device), beep periodically until one shows up. This is
   the mechanism for "which disc to insert next" when ripping several
   disc-owned games back to back -- the operator swaps discs between beeps.
   The helper itself doesn't verify disc identity mid-rip; the DAT hash
   check (step 3/6) is what ultimately confirms the right disc was read,
   after the fact, via the FOD hash mismatch failing the build.
1. Unmount the device if mounted (required before redumper touches it, and
   harmless for the plain-`dd` modes).
1. Run the actual rip: `dd` whole-image (`ripDisc`), `dd` + filesystem
   extraction (`ripDiscContents`, reusing `extractArchiveSnippet` from
   `lib/fetchers.nix:86-90`), or the `redumper` invocation above
   (`ripDiscRedumper`).
1. Write output to the path the build user can then copy into `$out`
   (root-run script, so drop permissive perms / chown back to the calling
   build user's uid on the output before returning).

`hosts/modules/config/doas.nix:11`: replace the placeholder
`"${dirs.HOME}/local/dvdrip"` rule (whose own comment already says "should
be updated ... when these are added" to the store) with a doas grant for
this new store-built script -- finishes what that comment was already
pointing at, instead of inventing a new convention.

### 6. Fetchers -- new file `lib/fetchers/disc.nix`

Auto-picked up by `lib/fetchers.nix`'s `builtins.readDir` import loop
(`lib/fetchers.nix:15-41`), same as `steam.nix`/`itch.nix`/etc. Three
exported functions, each invoking the shared helper from step 5 in its mode
and wrapped in the `flockBlock` from step 1:

- **`ripDisc { name, system, device ? "/dev/sr0" }`** -- raw whole-disc
  image (PS2). Looks up `datJson.${system}.${name}.sha1` (step 3's IFD'd
  table) instead of taking a caller-supplied hash. Plain FOD:
  `outputHashAlgo = "sha1"`, `outputHash = entry.sha1` (redump publishes
  sha1 -- use it directly, no re-hashing). `requiredSystemFeatures = [ "cdrom" ]`.

- **`ripDiscContents { name, device ? "/dev/sr0", sha256 }`** -- extracted
  filesystem tree (PC). Redump DATs describe raw disc dumps, not
  post-extraction file trees, so there's no DAT entry to look up here --
  keeps the caller-supplied `sha256`, same as originally planned.
  `requiredSystemFeatures = [ "cdrom" ]`.

- **`ripDiscRedumper { name, system, device ? "/dev/sr0", speed ? 8, retries ? 100 }`**
  -- accurate C2/subchannel dump, two modes selected by what step 3's DAT
  entry looks like for this title:

  - **Flat hash mode** (DAT entry is a single rom, e.g. most non-PS1
    systems): plain FOD wrapping one `disc-rip-helper --mode=redumper`
    call directly, `outputHash` from the DAT entry same as `ripDisc`.

  - **Multi-track mode** (DAT entry has a `tracks` list, e.g. PS1 cue/bin):
    the DAT already tells us -- at eval time, once step 3's JSON is loaded
    -- exactly which track filenames and hashes to expect, so this does
    **not** need the dynamic-derivation/`outputOf` machinery:

    1. `rawDump` -- one **non-FOD** derivation invoking the redumper
       helper once (root, physically reads the drive; not reproducible in
       the FOD sense since it's hardware-sourced, but that's fine, it's
       just an ordinary derivation).
    1. For each `tracks[]` entry: a small FOD `runCommand` (`outputHashMode = "flat"`, `outputHash = track.sha1`) that copies
       `${rawDump}/${track.name}` to `$out` -- built with `map` over the
       already-known track list, all eval-time constructed.
    1. Returns `{ cue = "${rawDump}/${name}.cue"; bins = [ <per-track FOD path> ... ]; }`.
       This gives per-track Nix-level caching/substitution (a later build
       that only needs track 2 doesn't re-touch hardware if that track's FOD
       is already in the store) without reviving `lib/optimize/dynamic.nix`'s
       heavier pattern -- the DAT supplies at eval time what that pattern
       exists to discover at build time.

  `requiredSystemFeatures = [ "redumper-drive" ]` on both modes.

### 7. Example: The Dig (ScummVM)

Smallest end-to-end example -- reuses the exact `games.scummvm.games` entry
shape every other ScummVM title in this repo uses (Kathy Rain precedent),
only the source-fetch step differs. PC disc -> extracted contents, so
`ripDiscContents`:

```nix
src = ripDiscContents {
  name = "the-dig";
  sha256 = "..."; # pinned after first successful rip on monyarm
} |> compressScummvmGame "scumm";
```

Added to `hosts/home/monyarm/games/Doom/wad/...` -- actually the ScummVM
games directory (find the sibling to Kathy Rain's entry, likely under
`hosts/home/monyarm/games/ScummVM/` per the earlier `git status` showing
that path already exists) alongside the other `games.scummvm.games` map
entries.

## Files to create/modify

- `sources.toml` -- `[git]` entries pinning the redump DAT GitHub mirror(s)
  needed (PS1 at minimum, for the multi-track path; others as needed)
- `py/dat-to-json.py` (new) -- Logiqx XML -> JSON, keyed by system/title
- `lib/fetchers/disc.nix` (new) -- DAT JSON IFD load, `ripDisc`,
  `ripDiscContents`, `ripDiscRedumper`
- new store-built privileged helper script (`disc-rip-helper`, packaged via
  nix, not a loose home-dir file) -- does the announce/beep-until-inserted
  loop, unmount, and actual `dd`/`redumper` invocation as root
- `hosts/modules/base/default.nix` -- add `"redumper-drive"` to monyarm's
  `supportedFeatures` (`"cdrom"` already present)
- `hosts/modules/config/doas.nix` -- replace the `~/local/dvdrip` rule with
  a passwordless-root grant for the new helper script's store path
- ScummVM games file -- add The Dig entry using `ripDiscContents`

## Verification

- `nix eval .#homeConfigurations.monyarm.activationPackage` (or equivalent
  flake check) to confirm `lib/fetchers.nix` picks up `disc.nix`, the DAT
  JSON derivation builds and IFD-loads cleanly, without eval errors.
- Confirm the pinned nixpkgs `redumper`'s actual `--help` output matches
  the flags assumed above (`--drive`, `--image-name`, `--image-path`,
  `--speed`, `--retries`, `--dvd-raw`) before wiring `ripDiscRedumper` --
  the README used for this plan was fetched off `main`, not the pinned rev.
- Spot-check `dat-to-json.py`'s output against a couple of known redump DAT
  entries by hand (one single-rom title, one multi-track PS1 title) to
  confirm the JSON shape matches what `disc.nix` expects before wiring the
  fetchers to it.
- `nix build` each of the three fetchers against a real inserted disc on
  `monyarm`: confirm the flock, the `cdrom`/`redumper-drive` feature gate,
  the beep/announce-and-wait loop, the doas-gated privileged read, the DAT
  hash lookup, and (for a multi-track title) the per-track FOD split all
  work end to end -- this is the actual disc-ripping proof, can't be faked
  without the physical media present.
- `nix build` The Dig's ScummVM entry once the sha256 is pinned from that
  successful rip, then launch it via the existing ScummVM game-launch path
  to confirm the ripped content is actually playable (not just
  hash-correct).
