# Migrate `nix profile` packages into the flake

## Background

Root cause of the Audacity "zero input devices" bug: `nix profile install` pins its own
nixpkgs revision, so it links a different glibc than the rest of the system. Any
imperatively-installed package carries that ABI risk. Moving them into the flake makes them
build against the same `pkgs`.

Secondary goal: reorganise `hosts/modules/packages/`, which currently mixes dev tools into
the nix-tools file.

## Findings (verified with `nix eval` / source inspection)

- `nix profile list` has **94 entries, not 55**. 39 are undocumented in
  `NIX_PROFILE_MIGRATION.md`.
- All 91 `legacyPackages` attrs resolve in the flake's nixpkgs.
- **Already provided by the flake** — profile copies are redundant: `cargo`, `claude-code`,
  `nodejs`, `opencode`, `yt-dlp`, `fuse`, `nix-prefetch-git`, `snes9x-gtk`,
  `mame`/`mame-tools`, `nix-output-monitor`, `maxima-cli`.
- **`git-lfs` is a live gap**: `Git.nix` configures LFS filters but
  `programs.git.lfs.enable` evaluates `false` and git-lfs is absent from `home.packages`.
  The profile copy is what satisfies `git lfs` today.
- **ARM toolchain is fine**: `pkgsCross.arm-embedded` already carries
  `newlib-arm-none-eabi-4.6.0.20260123` + `binutils-2.46`, matching devkitARM r68's own
  floor. Only gap is GCC 15.3 vs 16.1. No `arm-none-eabi-gdb` in nixpkgs — devkitARM ships
  none either.
- **`cards.json` is a bot, not plugin config**: pinned `ASF.cs` at tag `6.3.6.1` registers
  every `*.json` in `config/` as a bot. Your log confirms — bot `cards`, `SteamLogin: monyarm`.
- **ASF db files are continuously rewritten** (every `BotDatabase` setter calls `Save()`), so
  they cannot be Nix-managed store paths. `preStart` never deletes them, so a one-time move
  survives.

______________________________________________________________________

## Phase 1 — ArchiSteamFarm

### 1a. Secrets

```
sops set secrets/secrets.json --value-stdin '["archisteamfarm_password"]'
    # value piped from SteamPassword in ~/asf-config/config/cards.json
sops -e -i ~/asf-config/config/cards.maFile.NEW > secrets/archisteamfarm/cards.maFile.json
```

Password moves through a pipe — never printed, never in `ps`. `--value-stdin` exists for
exactly this.

The maFile is **JSON** (`file` reports "JSON text data"), so `.json` is accurate and required
by your `creation_rules` regex. `.sops.yaml` stays untouched.

### 1b. New `hosts/modules/services/archisteamfarm.nix`

```nix
{ config, ... }:
{
  services.archisteamfarm = {
    enable = true;
    settings.SteamOwnerID = 76561198033006574;
    bots.cards = {
      username = "monyarm";
      passwordFile = config.sops.secrets.archisteamfarm_password.path;
    };
  };
}
```

Follows the `tailscale.nix` pattern. Import at `hosts/nixos/gaming-laptop/configuration.nix:18`,
beside the existing `services/tailscale.nix` / `services/syncthing.nix` entries.

`passwordFile` emits `PasswordFormat = 4` (`ECryptoMethod.File`), so ASF reads the password
from the path. Verified `Encrypt(File, t) => t` and `HasTransformation(File) == false`
(`ArchiCryptoHelper.cs:88,137`) — switching 0→4 does **not** re-encrypt existing tokens in
`cards.db`, so no re-login or 2FA re-prompt.

### 1c. `secrets/default.nix`

Add `owner`/`group = "archisteamfarm"` for `archisteamfarm_password` in the
`lib.optionalAttrs isNixOS` block beside the syncthing keys (lines 48-57) — required because
the service runs `ProtectSystem = "strict"`. Add a `format = "json"` entry for
`archisteamfarm/cards.maFile.json`. The password key is auto-picked by `basicSecrets`
(line 41).

### 1d. Manual step — yours, live state

```
systemctl --user stop asf # currently PID 3249773, --path /home/monyarm/asf-config
mkdir -p /var/lib/archisteamfarm/config
mv ~/asf-config/config/{cards.db,ASF.db} /var/lib/archisteamfarm/config/
chown -R archisteamfarm:archisteamfarm /var/lib/archisteamfarm
chmod 700 /var/lib/archisteamfarm /var/lib/archisteamfarm/config
```

______________________________________________________________________

## Phase 2 — `Browser/`

```
hosts/home/monyarm/config/Browser/
├── default.nix                       # imports ./Chromium ./Firefox
├── bookmarks.nix                     # moved from Firefox/, canonical shared shape
├── bookmarks-private.sops.nix        # git mv from Firefox/
├── Chromium/
│   ├── default.nix                   # HM: enable, package
│   ├── extensions.nix                # the 2 web store IDs
│   └── extensions/                   # empty local drop dir
└── Firefox/                          # git mv whole dir, contents unchanged

hosts/modules/programs/chromium.nix   # NixOS layer: extraOpts.ManagedBookmarks,
                                      #   BookmarkBarEnabled
```

`git mv` throughout to preserve history. Nothing outside `Firefox/` references it by path —
the only external hits are `XDG.nix:14` (`firefox.desktop`) and `Niri.nix:120,140`
(`app-id = "firefox$"`), both runtime identifiers.

**Chromium policies must live in the NixOS layer.** Stock Chromium on Linux reads **only**
`/etc/chromium/policies/` — verified from `policy_paths.cc`
(`kPolicyPath[] = "/etc/chromium/policies"`), `chrome_browser_policy_connector.cc:350-362`
(machine scope, no user sibling), and `docs/enterprise/policies.md`. There is no XDG policy
dir, so writing `~/.config/chromium/policies/` silently does nothing. HM's
`programs.chromium` has zero policy support (0 matches for "polic"), so the NixOS module is
the only route.

`modules/programs/chromium.nix` lands in `configuration.nix:20`'s existing
`"${dirs.modules}/programs"` — **no configuration.nix edit needed for Chromium**. It imports
`Browser/bookmarks.nix` for the shared list.

### `Chromium/extensions.nix`

Both existing extensions fetched and identified:

| ID | Name | Version | MV |
| ------------------------------ | -------------------------- | -------------- | -- |
| `baleoognciaapjfjbhnibondmlodnddp` | OpenCode Browser Annotation | 0.6.2 | 3 |
| `ddkjiahejlhfcafbddmgiahcphecmpfh` | uBlock Origin Lite | 2026.930.1227 | 3 |

No CRX vendoring needed — HM's default `updateUrl` is already the web store endpoint
(`chromium.nix:10`), so `{ id = "..."; }` alone suffices and preserves auto-updates.

```nix
{ programs, ... }:
{
  programs.chromium.extensions = [
    { id = "baleoognciaapjfjbhnibondmlodnddp"; } # OpenCode Browser Annotation
    { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
  ];
}
```

`Preferences` also lists `mhjfbmdgcfjbbpaeojofohoefgiehjai` (Chromium PDF Viewer) and
`nkeimhogjdpnpccoofpliimaahmaaome` (Google Hangouts), but both are `location: 5`,
`from_webstore: false` — **built-in component extensions**, not installable, and must not be
listed.

### Shared bookmarks

Canonical shape in `Browser/bookmarks.nix` uses Firefox's `{ name, url }` /
`{ name, bookmarks }` — already what the private sops file uses. Each side maps:

- `Firefox/bookmarks.nix` — passes through to `programs.firefox.profiles.default.bookmarks`
  (unchanged)
- `modules/programs/chromium.nix` — `bookmarks` → `children`, drops `toolbar`, prepends
  `{ toplevel_name = "Bookmarks Toolbar"; }` → `extraOpts.ManagedBookmarks`

Chromium policy keys are **lowercase** (`managed_bookmarks_tracker.cc:30-33`): `name`, `url`,
`children`, `toplevel_name`. Folder = has `children`, no `url`. Nesting is arbitrarily deep.
Policy name is `ManagedBookmarks` — there is no `Bookmarks` policy and no deprecated alias.

Also set `BookmarkBarEnabled = true` (Chromium otherwise defaults to bar-on-NTP-only). Note
the entire managed subtree is immutable in Chromium's UI and doesn't sync.

The private sops file is 2 flat folders × 52 leaf bookmarks, no deeper nesting — maps cleanly
to `children` recursion. `git mv` needs no re-encryption.

______________________________________________________________________

## Phase 3 — package split

**Ungated** (`environment.systemPackages`, both gaming-laptop and gentoo-system):

- **`base.nix`** — flat list, dropping the `dev` bucket's `concatLists (attrValues {...})`
  indirection:
  `appimage-run bat bc curl diskus eza entr file git gnupg htop inotify-tools jq p7zip ripgrep rs socat sqlite sshfs tree unrar unzip wget`
- **`nix.nix`** — nix tooling only. **Moves out** `dotnet-sdk_8`, `hyperfine`, `rust-analyzer`.

**`lib.mkIf isHomeManager`-gated:**

- **`dev.nix`** — those three + `direnv`/`yarn`, `programs.gcc`,
  `gdb valgrind pkg-config android-tools gnumake`,
  `pkgsCross.arm-embedded.stdenv.cc`, `qemu openocd`, runtimes
  (`elixir nim nimble luajit luarocks nodejs python311 capstone numpy cargo sops`), and all
  lib entries incl. the non-`.dev` ones
- **`media.nix`** — `audacity dejavu_fonts ffmpeg gimp imagemagickBig inkscape pdf-cli pdfarranger poppler-utils sox vips`
- **`apps.nix`** — `feh nemo transmission_4 scrcpy wtype winetricks wine`; `flatpak` goes
  into `Flatpak.nix`'s existing `home.packages` beside `pkgs.expect`
- **`games.nix`** — `ccd2iso maxcso mame-tools steamguard-cli`

`default.nix` imports all six. New files follow `nix.nix`'s `lib.mkMerge` over
`isNixOS`/`isHomeManager`; the four gated ones use `lib.mkIf isHomeManager` to stay off
headless gentoo-system.

**Dropped entirely:** `snes9x` (repo already has `pkgs.snes9x-gtk` at `emulators.nix:136`),
`litecli`, `mutagen`, `nixos-install-tools`. `maxima-cli` and `nix-output-monitor` are never
added — the flake resolves them by absolute path (`packages/game-library-scan.nix:31`) or in
`nix.nix`.

**`unrar` stays.** nixpkgs' `unrar` ships RARLAB's *free portable* UnRAR license —
redistributable, no trial. And `p7zip` genuinely cannot do RAR:
`pkgs/by-name/p7/p7zip/package.nix:5` defaults `enableUnfree ? false`, and lines 26-29
`rm -r $out/CPP/7zip/Compress/Rar*` at fetch time.

______________________________________________________________________

## Phase 4 — module migrations

- `programs.cargo` / `programs.gh` replace the raw entries in `shell.nix`.
- `Git.nix`: set `programs.git.lfs.enable = true` and **delete `Git.nix:12-17`** — the
  `filter.lfs` block only. `user`, `core`, `pull`, `credential`, `http`, and `signing` all
  stay. The module generates identical `clean`/`smudge`/`process`/`required` keys, so keeping
  both would emit a duplicate `[filter "lfs"]` section in the same generated `gitconfig`.
- ARM stays on `pkgsCross.arm-embedded`; no devkitPro, no PSP. This also corrects the
  installed 15.2.0 wrapper, whose `orig-libc` points at glibc rather than newlib.

______________________________________________________________________

## Phase 5 — verify, then remove

```
nix fmt
nix flake check
nix build .#nixosConfigurations.gaming-laptop.config.system.build.toplevel
```

No activation, per `AGENTS.md` — and ASF's service stays down until you switch, which is why
1d is a manual step.

Then `nix profile remove` the redundant entries in themed batches (including `snes9x`), and
rewrite `NIX_PROFILE_MIGRATION.md` with the real 94-entry inventory and what became of each.

Batching by theme keeps breakage bisectable — wine/gamescope need extra NixOS-level config
for game tooling.

______________________________________________________________________

## Known non-goals

- **PSP toolchain** — dropped by decision. `pspdev/pspdev-nix` exists with a Cachix cache if
  you revisit.
- **Chromium bookmarks vs Firefox bookmarks** are declaratively managed separately and can't
  share a single rendered artifact; only the *data* is shared.
- **`steamguard-cli`, `maxcso`, `ccd2iso`, `mame-tools`** are added on faith — no reference
  found in your config, unlike `feh` (`I3.nix:319`) or `qemu` (`ZSH/env.nix:29`).
