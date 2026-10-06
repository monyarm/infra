# Migrate `nix profile` packages into the flake

**Status: done.** The imperative profile is empty (`nix profile list` returns nothing);
every package now comes from the flake. This file is the record of what each of the 94
profile entries became.

## Why

`nix profile install nixpkgs#<pkg>` pins its own nixpkgs revision, so the package links
against a different glibc than the rest of the system. Audacity shipped
`glibc 2.40-66` while everything else was on `2.42-67`, which broke `dlopen()` of
PipeWire's ALSA plugin — silent, total device-enumeration failure with no error anywhere.
Any imperatively-installed package carried that risk.

## What was there

94 entries, not the 55 originally documented. Grouped below by what happened to each.

### Now in the flake (88 removed from the profile)

**System-level** (`environment.systemPackages`, both hosts) — `hosts/modules/packages/base.nix`:
`appimage-run bat bc curl diskus entr eza file git gnupg htop inotify-tools jq p7zip ripgrep rs socat sqlite sshfs tree unrar unzip wget`

**Nix-level** (`nix.nix`, also `environment.systemPackages`): `dconf2nix nix-output-monitor nix-prefetch nix-rom nixd nixfmt nurl nh` + Determinate's `nix`.

**Dev toolchain** (`dev.nix`, home-manager only): `pkgsCross.arm-embedded.stdenv.cc qemu openocd android-tools gdb gcc gnumake pkg-config radare2 valgrind cargo elixir luajit luarocks nim nimble nodejs python311 sops capstone numpy dotnet-sdk_8 hyperfine rust-analyzer direnv yarn` and the C/C++ libraries — `SDL2(.dev) freetype(.dev) libmpeg2 libogg(.dev) libpng(.dev) libvorbis(.dev) libvpx(.dev/.out) libx11.dev openh264(.dev) vips.dev xorg.libX11`.

**Media** (`media.nix`): `audacity dejavu_fonts ffmpeg gimp imagemagickBig inkscape pdf-cli pdfarranger poppler-utils sox vips`

**Apps** (`apps.nix`): `feh flatpak geeqie nemo scrcpy transmission_4 winetricks wine wtype`

**Games** (`games.nix`): `ccd2iso gamescope maxcso mame-tools steamguard-cli`

### Switched to modules instead of raw packages

| Was | Now |
| --- | --- |
| `git-lfs` profile copy | `programs.git.lfs.enable = true` (was evaluating `false`) |
| `gcc` | `programs.gcc.enable` |
| `gh` | `programs.gh.enable` |
| `chromium` | `programs.chromium` |
| `firefox` | `programs.firefox` (was already) |
| `ArchiSteamFarm` | `services.archisteamfarm` with `passwordFile` |

### Deliberately not added

| Package | Why |
| --- | --- |
| `maxima-cli` | `lib/fetchers/origin.nix` uses it as a `nativeBuildInput` (stdenv PATH), never from the user profile. |
| `snes9x` | Repo already uses `pkgs.snes9x-gtk` (`emulators.nix`); the profile copy was the non-gtk SDL build. |
| `xorgproto` | Ships the same `include/X11/extensions/*.h` as `libx11.dev`. `home.packages` is one `buildEnv`, which hard-fails on conflicting subpaths. `libx11.dev` wins. |
| `nixos-install-tools` | 24.11-era ISO leftover with no flake attr. The running system has `nixos-install`/`nixos-rebuild-ng`. |
| `litecli` | Not wanted — `sqlite` covers it. |
| `mutagen` | Not wanted. |
| `nix-diff` | Redundant with `nix flake diff`. |
| `fira-code` | Stylix's `nerd-fonts.fira-code` already provides it. |

## ArchiSteamFarm

Migrated to `hosts/modules/services/archisteamfarm.nix`. Two things worth knowing:

**`cards.json` is a bot, not plugin config.** Pinned `ASF.cs` at tag `6.3.6.1` registers
*every* `*.json` in `config/` as a bot (`Directory.EnumerateFiles(config, "*.json")`,
filtered only by `IsValidBotName`). Field 4 of a log line is the NLog logger name, and a
bot's logger is built from the bot name (`Bot.cs:328`). Card farming is a built-in `Bot`
member, not the plugin.

**The password never touches disk.** The module emits
`SteamPassword = <secret path>; PasswordFormat = 4` and `preStart` contains no
`replace-secret`, so ASF reads `/run/secrets/archisteamfarm_password` directly. Verified
in the generated config:

```json
"SteamPassword": "/run/secrets/archisteamfarm_password"
"PasswordFormat": 4
```

Switching `PasswordFormat` 0→4 does not re-encrypt the existing tokens in `cards.db` —
`ArchiCryptoHelper.Encrypt` is a no-op for `File` and `HasTransformation(File)` is `false`
(lines 88, 137). So no re-login and no 2FA re-prompt.

State migration is `/tmp/opencode/asf-state.sh` (`move` / `chown` / `verify` /
`shred-mafile`). `cards.db` holds live login keys and the ASF 2FA secret — the script
refuses to run if ASF is live, and `chown` refuses until the `archisteamfarm` account
exists.

## Secrets

`secrets/secrets.json` gained `archisteamfarm_password`; the maFile is at
`secrets/archisteamfarm/cards.maFile.json`. Both need `owner`/`group = "archisteamfarm"` —
`sops-install-secrets` resolves `owner` through NSS at build time and hard-fails if the
account is absent, so a literal fallback is not a substitute for actually creating it.

Both standalone files use `format = "binary"`. `format = "json"` means "this secret is a
key *inside* a JSON document" — sops splits the name on `/` and walks each segment
(`sops-install-secrets/main.go:290-320`), which is why `archisteamfarm/cards.maFile.json`
failed with `the key 'archisteamfarm' cannot be found`. Binary format stores the whole
file and round-trips byte-identically.

## Browser

`Browser/` holds Firefox (moved with `git mv`) and Chromium. Shared bookmarks live in
`Browser/data/bookmarks.nix` — **not** beside `default.nix`, because `autoImport` treats
every non-`default.nix` file in a config directory as a module
(`lib/imports.nix`: `exclude = [ "default.nix" ]`), so a data file would fail on its
`mkBookmark`/`toolbar` keys.

Chromium's half is split across layers: `Browser/Chromium/` has the home-manager side
(package + the two web-store extensions), and `hosts/modules/programs/chromium.nix` has
the NixOS side (`ManagedBookmarks`, `BookmarkBarEnabled`). That split is forced —
Chromium reads managed policies from `/etc/chromium/policies/` only, with no XDG user
policy dir (`policy_paths.cc`), and HM's `programs.chromium` exposes no policies option.
Policy keys are lowercase (`name`/`url`/`children`/`toplevel_name`,
`managed_bookmarks_tracker.cc:30-33`); the whole managed subtree is immutable in the UI.

Chromium's 3rd and 4th profile-time extensions are built-in components
(`location: 5`) — Chromium PDF Viewer and Google Hangouts — not installable, and
correctly absent from `extensions.nix`.

## Packages/`isHomeManager` caveat

Modules under `hosts/modules/packages/` are imported by **NixOS**, where `isHomeManager`
is `false`. `dev`/`media`/`apps`/`games` are therefore registered in `hosts/default.nix`'s
`homeManagerModules` instead — a module imported from the NixOS tree could never set
`home.packages`. (`nix.nix`'s own `home.packages` branch has this latent bug already,
which is why `nixd`/`nh` are system packages rather than home packages.)

## ARM

`pkgsCross.arm-embedded` is kept; no devkitPro flake. It already carries
`newlib-arm-none-eabi-4.6.0.20260123` and `binutils-2.46`, matching devkitARM r68's own
floor — the only gap is GCC 15.3 vs 16.1. There is no `arm-none-eabi-gdb` in nixpkgs and
devkitARM ships none either, so `qemu` + `openocd` cover debugging. Migrating off the
profile also corrects a real bug: the installed 15.2.0 wrapper had `orig-libc` pointing at
glibc rather than newlib.

PSP tooling (`pspdev-nix`) was dropped by decision.

## After deploying

The build is verified; the *running* system still has the old generation until you deploy.
Nothing from the old profile is on `PATH` right now, so `audacity`, `chromium`, `gimp`,
`radare2`, `git-lfs` etc. only reappear after `deploy.sh gaming-laptop`.

Note that `deploy.sh` runs `git add .`, which will stage the unrelated GIMP config churn
alongside this work.

## mame-tools is an output selection, not a different package

Worth writing down because it looks like a duplicate and isn't.
`pkgs.mame-tools` is `pkgs.mame.override { outputs = [ "out" "tools" ]; }` — the same
`drvPath`, but selecting the second output. `$out` holds only `mame`; `$tools` holds the
16 utilities: `castool chdman floptool imgtool jedutil ldresample ldverify mame-split nltool nlwav pngcmp regrep romcmp srcclean testkeys unidasm`.

So `pkgs.mame` on its own puts none of those on `PATH`. Both are in `home.packages` --
`games/Emulation/arcade/default.nix` uses `pkgs.mame` for the emulator wrapper, and
`games.nix` adds `mame-tools` for the utilities. Note `split` is installed as `mame-split`
to avoid colliding with coreutils.

Comparing `drvPath` alone is not a valid "already covered" test for multi-output packages.
