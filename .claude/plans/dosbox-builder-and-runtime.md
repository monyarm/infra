# DOSBox Builder and Runtime Research

## Recommendation

Use three explicit runtime modes:

1. DOSBox Staging for ordinary extracted DOS games.
1. DOSBox-X for CHD, Windows 3.1, unusual media, and disk images.
1. DOSBox Pure Unleashed/Pure for ZIP/DOSZ packages with automatic external overlays.

Do not force all games through one emulator backend.

## Fork Findings

### DOSBox Staging

Best default for normal DOS game directories.

- Strong performance and modern defaults.
- Native directory overlay mounts:
  `mount C /game`
  `mount C /saves -t overlay`
- Supports ISO, CUE/BIN, MDS/MDF, IMG, IMA, and VHD.
- Does not support CHD.
- Best fit for immutable Nix game data plus writable XDG state.
- Current storage documentation recommends `mount`; `imgmount` is deprecated.

Source:
https://www.dosbox-staging.org/0.83/manual/using-dosbox-staging/storage/

### DOSBox-X

Best compatibility and CHD support.

- Supports CHD v5 CD/DVD images, including mixed data/audio discs.
- Supports raw, VHD, QCOW2, and unusual floppy formats.
- Strong Windows 3.x/9x, FAT32, PC-98, DOS/V, and device support.
- QCOW2 copy-on-write layers work, but must be created externally.
- More complex and potentially heavier than Staging.

Source:
https://dosbox-x.com/wiki/Guide%3AManaging-image-files-in-DOSBox%E2%80%90X

### DOSBox Pure

Best archive/overlay model.

- ZIP/DOSZ content is mounted without extraction.
- Runtime changes go to a separate `.pure.zip`.
- Supports direct CHD loading, but only:
  - uncompressed CHD;
  - version 5;
  - CD-ROM images.
- Compressed CHD and hard-disk CHD are unsupported.
- CHD inside ZIP/DOSZ is not reliably documented.

Sources:
https://github.com/schellingb/dosbox-pure
https://github.com/schellingb/dosbox-pure/issues/40

### DOSBox Pure Unleashed

Standalone desktop version of DOSBox Pure.

- Official standalone project:
  https://github.com/schellingb/dosbox-pure-unleashed
- Builds on Linux, macOS, and Windows.
- Inherits Pure's partial CHD support.
- Uses Pure's external writable overlay model.
- No documented general headless mode.

### DOSBoxPureStandalone

Downstream one-file Windows packager.

- Project:
  https://github.com/Buyukcaglar/DOSBoxPureStandalone
- Embeds ZIP/DOSZ content and runtime into one Windows executable.
- Does not extract the game archive.
- Stores changes externally under `%LOCALAPPDATA%`.
- Supports overlay layering and reusable system-shell DOSZ files.
- Generated package is Windows-specific and not directly suitable as a Linux/Nix artifact.
- Its documented package format is ZIP/DOSZ, not CHD.

## Packaging Model

Use format according to media type:

| Content | Immutable artifact | Writable layer |
| --- | --- | --- |
| Extracted DOS game | Nix directory or ZIP/DOSZ | Staging overlay or copied directory |
| CD game | Compressed CHD | Writable C: directory |
| Bootable DOS/Windows | Raw FAT image or VHD | QCOW2 child image |
| Pure package | ZIP/DOSZ | `.pure.zip` |
| Windows standalone package | Embedded ZIP/DOSZ PE executable | External Pure overlay |

CHD is a distribution format for immutable CD media, not a general writable filesystem.

For multiple writable layers, prefer QCOW2 backing chains for disk images. For directory games, use one emulator overlay or host OverlayFS/fuse-overlayfs. Multiple Staging overlay layers should not be assumed without testing.

## Windows 3.1 Base Image

Windows 3.1 supports unattended setup through a system settings file:

```dos
SETUP /H:SETUP.SHH
```

The exact values must match the selected media's `SETUP.INF`.

Example:

```ini
[sysinfo]
showsysinfo=no

[configuration]
machine=ibm_compatible
display=vga
mouse=ps2mouse
language=enu

[windir]
c:\windows

[userinfo]
"User Name"
"Company Name"

[dontinstall]
games
readmes

[endinstall]
configfiles=save
endopt=exit
```

Build procedure:

1. Preserve and hash the original Windows disks.
1. Extract every disk into one `INSTALL` directory.
1. Create a clean DOS environment.
1. Run `SETUP /H:SETUP.SHH`.
1. Use VGA during initial installation.
1. Install compatible S3/video, mouse, and Sound Blaster drivers afterward.
1. Shut down cleanly.
1. Snapshot the folder tree or FAT image.
1. Test it from a fresh emulator configuration.
1. Keep the base immutable and create per-game writable layers.

Use a folder-mounted C: tree for simplicity. Use a bootable raw FAT image when preserving boot-sector, partition, and filesystem behavior matters.

Sources:

- https://dosbox-x.com/wiki/Guide%3AInstalling-Windows-3.1x
- https://www.dosbox-staging.org/0.83/manual/using-dosbox-staging/windows-31/
- https://archive.org/stream/bitsavers_microsoftr5Windows3.1ResourceKit199202_48972813/0030-31645_Windows_3.1_Resource_Kit_199202_djvu.txt

## Repository Changes

Current helper:

`lib/fetchers/dosbox.nix`

Findings:

- Defines `buildDosBox`, despite living under `fetchers`.
- Has no active callers.
- Defaults to DOSBox Staging.
- Mounts the build directory as C:.
- Treats every non-directory mount as an `imgmount`.
- Runs DOSBox under Xvfb during derivation builds.
- Is build-time oriented, not a runtime package launcher.

Move it to `lib/builders/` rather than `packages/`.

Required wiring:

- Add a builders aggregator analogous to `lib/fetchers.nix`.
- Preserve the public `buildDosBox` attribute unless deliberately breaking callers.
- Update `lib/default.nix`.
- Update stale references in `GAME_IDEAS.md`.
- Keep package discovery and overlay wiring unchanged unless a real package is added.

## Builder API Direction

The builder should distinguish media types instead of inferring all non-directories as images.

Suggested conceptual inputs:

```nix
buildDosBox {
  pname = "...";
  version = "...";
  emulator = pkgs.dosbox-staging;
  drives = {
    c = { type = "directory"; source = game; writable = false; };
    d = { type = "chd"; source = disc; writable = false; };
  };
  overlay = {
    type = "directory";
    path = "$XDG_DATA_HOME/game";
  };
  dosboxScript = "...";
}
```

Do not implement this API until the runtime and build-time use cases are separated. The current helper should first be relocated with behavior preserved, then extended minimally.

## Validation

- Confirm Staging directory overlays preserve the immutable lower directory.
- Confirm DOSBox-X mounts compressed CHD CD images.
- Confirm Pure accepts only uncompressed CHD v5 CD images.
- Build and boot the Windows 3.1 base from a clean image.
- Run an unattended `.SHH` installation using the exact Windows media.
- Verify game writes never target `/nix/store`.
- Verify separate overlays survive emulator restarts.
- Run `nix flake check`.
- Do not activate Home Manager or NixOS.
