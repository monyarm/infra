# Migrate the `monyarm` Gentoo server to NixOS

## Goal

Reinstall the Gentoo box (`ssh monyarm`) as NixOS with every service still working,
configuration living in this flake rather than in `/etc` and hand-run scripts. All
MediaWiki extensions managed through `sources.*`.

## Current state (inspected 2026-10-06 via `ssh monyarm`)

**Host:** Gentoo Linux, **OpenRC** init, Determinate Nix 3.22.2. `/home` bind-mounted from
`/mnt/HDD/home`, `/nix/store` bind-mounted from `/mnt/Media/store`. ZFS `media` (7.27T,
3.77T used) at `/mnt/Media`. `trusted-users = monyarm`, `max-jobs = 16`.

**Docker** — one compose project `container` at `container/docker-compose.yml`, 5 containers:

| Container | Image | Exposure | State |
| --- | --- | --- | --- |
| `floppy` | `ghcr.io/dannyvfilms/floppy:latest` | `8000:8000` | healthy, requires redis |
| `floppy-redis` | `redis:8-alpine` | internal `floppy-net` | healthy |
| `container-audiobookshelf-1` | `ghcr.io/advplyr/audiobookshelf:latest` | `13378:80` | up |
| `container-homeassistant-1` | `ghcr.io/home-assistant/home-assistant:latest` | host net, `8123` | up |
| `container-matter-1` | `ghcr.io/matter-js/python-matter-server:stable` | host net, `5580` | up |

Bind mounts all live under `/mnt/Media`: `MatterData`, `HAConfig`, `AudioBooks`, `Podcasts`,
`ABConfig`, `ABMetadata`. Two named volumes: `floppy_db`, `redis_data`. Redis runs with
`--appendonly yes --save "" --maxmemory 256mb --maxmemory-policy volatile-lru` and a
`redis-cli ping` healthcheck.

**OpenRC services** (34 started): `jellyfin` (8096), `lighttpd` (80), `mysql` (3306, bound to
`127.0.0.1`), `syncthing` (8384), `docker`, `tailscale`, `libvirtd` + `libvirt-guests`,
`cupsd`, `avahi-daemon`, `bluetooth`, `zfs-zed` + `zfs-share`, `qemu-binfmt`, `cronie`,
`dhcpcd`, `NetworkManager`.

**libvirt VMs** (both shut off, need `virtualisation.libvirtd` + XML migration): `freedos1.2`,
`nixos-unstable`.

**Syncthing** — 4 folders: `default` → `/home/monyarm/Sync`,
`et6zq-2tmqe` → `~/Pictures/Phone Wallpapers`, `hqrrn-9mxsg` → `~/Documents/Obsidian Notes`,
plus one `~` receive-only. Peers: `monyarm-desktop`, `monyarm-laptop`, `motorola one fusion+`,
`motorola edge 40 neo`. Config at `~/.config/syncthing/config.xml`, with its own `key.pem` and
`https-key.pem`.

**Web stack** — lighttpd + spawn-based `php-cgi` 8.3.
**Docroot is `/var/www/localhost/htdocs`, not `/var/www/htdocs`** (`var.basedir = "/var/www/localhost"`). Replaced by the standard NixOS path `/var/www/html`.

| Site | Size | State |
| --- | --- | --- |
| `kitbash_list` | 4.8G | 24 per-game SQLite DBs + `kitbash_list.sqlite`, `node_modules` (13M) |
| `momir_basic` | 4.5G | `momir_basic.sqlite` + backups, `node_modules` (12K) |
| `mtg_wishlist` | 560M | `wishlist.db` |
| `mediawiki` | 534M | 4 SQLite DBs, `LocalSettings.php`, `vendor/`, SemanticMediaWiki + ~30 extensions |
| `booktracker` | 135M | `tracker.sqlite`, `vendor/` (9M) |
| `minifig-tracker` | 1.7M | `schema.sqlite.sql`, env-driven DB (mysql 3306 / sqlite / pgsql) |
| `V5` | 300K | no DB |
| `army` | 1.4M | 12 armies across 4 systems, see below |

**Out of scope** (per decision): `cardconjurer` (a *dangling* symlink to
`/mnt/Media/cardconjurer`, which does not exist), `CookieClicker`, and `test` (403 — no index
file, `dir-listing` disabled).

### Live bugs found

1. **MediaWiki is unreachable.** `LocalSettings.php:216` hardcodes
   `$wgServer = 'https://' . $_serverName`, so every request 301s to `https://` — and
   **nothing listens on 443**. No `tailscale serve`, no cloudflared, no reverse proxy.
   `curl` confirms `Failed to connect to 127.0.0.1 port 443`.
1. **`minifig-tracker` 404s.** `Request::path()` (`src/App/Core/Request.php:23`) returns the
   raw `REQUEST_URI`, so served at `/minifig-tracker/public/` it matches no route (routes
   expect `/`, `/api/v1/...`). Its `.htaccess` is Apache syntax that lighttpd never
   processes, so the rewrite was already dead.
1. `test/` 403s — dropped anyway.

### Site sourcing

| Site | GitHub | Branch | Dirty |
| --- | --- | --- | --- |
| `booktracker` | `git@github.com:monyarm/Claude-Code-Work.git` | `claude/ttrpg-book-tracker-445zhv` | 1 (`config.json`) |
| `kitbash_list` | `git@github.com:monyarm/KitbashList---Card-Tracker.git` | `master` | **5 files** |
| `minifig-tracker` | `https://github.com/monyarm/Claude-Code-Work` | `claude/lego-minifigure-tracker-ho7rcd` | clean |

`kitbash_list`'s 5 changes get committed and pushed. `booktracker` and `minifig-tracker`
stay on their feature branches. The other 5 sites are not git repos.

### Secrets — two problems

`/home/monyarm/.nix/.env` holds 17 plaintext exports, symlinked as `container/.env`.

- **10 keys are already sops-encrypted** in `secrets/env.json`: `EPIC_LEGENDARY_AUTH`,
  `GOG_AUTH`, `ITCH_API_KEY`, `MAXIMA_AUTH`, `NINTENDO_COOKIE`, `STEAMGRIDDB_API_KEY`,
  `STEAM_API_KEY`, `STEAM_PASSWORD`, `STEAM_SHARED_SECRET`, `STEAM_USERNAME`. Read by
  `lib/fetchers/{epic,gog,origin,nintendo,steam}.nix`, `packages/game-library-scan.nix:513`,
  `packages/capcom-arcade-scan.nix:177`, `steamgriddb-proxy.py:48`.
- **7 keys are plaintext-only and must be added**: `FLOPPY_SECRET`, `TMDB_API`, `MAL_API`,
  `IGDB_ID`, `IGDB_SECRET`, `BGG_API_TOKEN` (currently *empty*), `COMICVINE_API`,
  `GOOGLE_BOOKS_API_KEY`.

Those 7 are consumed only by the `floppy` container. Once encrypted and the compose file is
generated by Nix, the plaintext `.env` can be deleted.

### The `army` site

12 armies / 4 systems, each `<Name>.html` + `.png` + `.txt`:

- `Mordheim/`: Fashion Army
- `Warhammer 40,000/`: Amazon Tyranids, Blood Ravens, Death Guard, Henshin Marines,
  Night Lords, Orks, Phyrexian Necrons, Rebel Grots, T'au Sentai
- `Warhammer Fantasy: Age of Sigmar/`: Nighthaunt
- `Warhammer Fantasy: Old World/`: Tomb Kings

All 12 `.html` files are 4-byte `WIP\n` stubs hardlinked to one inode. Every `.txt` reads
`"Placeholder description for <name>."`.

**`archive.7z` contains a real 23,255-byte `Blood Ravens.html`** — a complete 1st Company
Task Force roster (Chaplain, Invulnerable Save 4+, Spiritual Leader, Oath of Moment, Pistol
rules). The live tree replaced it with a `WIP` stub. This is the reference for the eventual
per-army page generator.

`T'au.txt` / `T'au.png` are leftovers with no matching `.html`, so `index.php`'s
`glob("*/" . "*.html")` loop skips them and they never appear. **Dropped** per decision.

`index.php` scans directories at request time and emits `armies_json` to inline JS;
`functions.php` only holds `getColspan()`.

Per decision: declare the armies as Nix data (system + name + description + image) so the
entries are reviewable and diffable in-tree. Per-army page generation is a **later phase**.

______________________________________________________________________

## Target architecture

### Podman, not Docker

`virtualisation.podman` + a `systemd` unit running `podman-compose` against a compose file
that **Nix generates**. Env vars come from sops; no plaintext `.env` on disk.

The 7 floppy secrets inject via `config.sops.secrets.*.path`. Keep the 5 images as-is —
reimplementing Home Assistant, Audiobookshelf, Matter and Floppy in pure Nix is out of scope
and high-risk. Migrating `floppy_db` and `redis_data` needs a one-time copy into podman paths.

### nginx + php-fpm per site

Replaces lighttpd's spawn-based FastCGI. `services.nginx` with one `server` block per site,
`services.php.fpm` pools. This also fixes `use-ipv6 = "disable"` and per-request `php-cgi`
spawns.

**Source-controlled** where it's our own code: `army`, `minifig-tracker`, `booktracker`,
`mtg_wishlist`, `V5`. `buildComposerApplication` / `buildNpmPackage` run at build time, so
`vendor/` and `node_modules/` are never committed.

**Runtime data only** (recorded in `TODO.md`, not git): all SQLite DBs, uploaded images
(`booktracker/public/covers`, `minifig-tracker/storage/uploads`, `momir_basic/public`),
`mediawiki/images`.

**Size reality check:** the large sites are data-dominated — `momir_basic` is 4.3G of its
4.5G in `data/`, `kitbash_list` 2.6G of 4.8G. Vendoring source is cheap; vendoring state
is not.

### HTTPS

nginx on **443 with a self-signed cert** (`security.pki`), HTTP→HTTPS redirect for 80.
Works on `monyarm`, the LAN IP, and the MagicDNS name — which is what the dynamic
`$wgServer` needs. Tailscale HTTPS was rejected as awkward for this use case.

### Autogenerated root index

`/var/www/html/index.html` is generated by Nix from the same list of site definitions that
drive the nginx `server` blocks, so it can never drift from what's actually served. Today's
hand-written file lists only 3 of 9 sites and its `<a href="wiki">` is wrong anyway (the wiki
is at `/mediawiki`).

______________________________________________________________________

## MediaWiki

- Live: **1.42**, SQLite, `$wgSitename = 'Miniature Compendium'`, `$wgScriptPath = '/mediawiki'`, `$wgArticlePath = '/wiki/$1'`, SemanticMediaWiki **5.0.0**.
- nixpkgs: **1.46.0**. SMW **7.3.0** is compatible with MW 1.43–1.46, PHP 8.1–8.5
  (`RELEASE-NOTES-7.3.0.md`).
- `services.mediawiki` generates `LocalSettings.php` from options. With
  `webserver = "nginx"` it emits `$wgArticlePath = "/wiki/$1"` + `$wgUsePathInfo = true` —
  matching current URLs.
- `mediawiki-init.service` is `Type = "oneshot"`, `wantedBy = [ "multi-user.target" ]`, and
  `restartIfChanged` defaults to `true`. Its unit text embeds the MediaWiki store path, so a
  flake version bump **changes the unit and re-triggers it on `nixos-rebuild switch`**. It
  runs `install.php` if `tableExists('user')` is false, then **always**
  `update.php --quick --skip-external-dependencies`. **Not atomic — back up the DB before
  every bump.**
- **Migration order: run 1.42's `update.php` on Gentoo first**, then point NixOS at the
  resulting DB. Never point 1.46 at a 1.42 schema directly.

### `extraConfig` requirements

```nix
extraConfig = ''
  # dynamic host: works via LAN name, IP, or MagicDNS
  $wgServer = 'https://' . ($_SERVER['SERVER_NAME'] ?? 'monyarm.chestnut-stargazer.ts.net');
  enableSemantics($_SERVER['SERVER_NAME'] ?? 'monyarm.chestnut-stargazer.ts.net');

  # Interwiki moved into core in 1.44; the extdist tarball is a MOVED_TO_CORE stub
  $wgGroupPermissions['sysop']['interwiki'] = true;

  $wgMaxShellFileSize = 10240000;
  $wgExtensionFunctions[] = function() {
    $GLOBALS['wgUploadNavigationUrl'] = SpecialPage::getTitleFor('MediaUploader')->getLocalURL();
    return true;
  };
'';
```

SMW's `enableSemantics($domain)` prefixes its namespace with `.domain`, so the SMW store is
per-hostname by design — preserved.

______________________________________________________________________

## Extensions via `sources.*`

nixpkgs has exactly one `mediawiki` package and **zero** extension packages (verified across
all ~20,200 attribute names). nixpkgs has never had an SMW PR (1 issue total, unrelated
BookStack changelog). No community flake covers the full set —
`github:Die-KoMa/mediawiki` (rev `d15b669`, pushed 2026-09-20) packages SMW + 8 others but
pins mediawiki **1.45.4** and covers only 4 of ours. **We copy their derivation; we do not
depend on the flake.**

### Triage (35 declared → 12 bundled, 19 external, 2 dropped)

| Source | Extensions |
| --- | --- |
| `null` (bundled in 1.46) | WikiEditor, CodeEditor, MultimediaViewer, PageImages, ParserFunctions, PdfHandler, TextExtracts, VisualEditor, InputBox, TemplateData, TemplateStyles, Scribunto — **12** |
| **drop** | `ExtensionName` (installer comment), `Interwiki` (core since 1.44; verified 632-byte `MOVED_TO_CORE` stub on REL1_46) |
| extdist `REL1_46` `fetchzip` | PageForms, ExternalData, DisplayTitle, MassEditRegex, Purge, Arrays, Loops, Variables, Widgets, DataTransfer, CategoryLinks, WhiteSpace, MediaUploader — **13** |
| **composer2nix** | SemanticMediaWiki — **1** |
| git-tag `fetchzip` | SemanticResultFormats, SemanticScribunto, SemanticCompoundQueries — **3** |

`PageInCat` → **`CategoryLinks`** (renamed in MW 1.44).

GitHub Releases is a dead end for the SMW family: SMW's `INSTALL.md` states *"SMW no longer
provides file releases"*, and every SMW/SRF/SSC/SCQ release has `assets = 0`. SRF/SSC/SCQ
tag archives do work.

### `sources.*` design

`[cargo]` is the exact precedent (`update-sources.py:987`): a section that references an
already-resolved `[git]`/`[git-tag]` source **by the same name**, resolves a lockfile
outside the Nix sandbox, and merges it into that source's result dict — never a separate
top-level key, because `main()`'s flat-key merge treats any dict with a `type` field as an
opaque leaf.

New `sources.mediawiki.toml`:

```toml
[git-tag]
mediawiki.SemanticMediaWiki       = "https://github.com/SemanticMediaWiki/SemanticMediaWiki"
mediawiki.SemanticResultFormats   = "https://github.com/SemanticMediaWiki/SemanticResultFormats"
mediawiki.SemanticScribunto       = "https://github.com/SemanticMediaWiki/SemanticScribunto"
mediawiki.SemanticCompoundQueries = "https://github.com/SemanticMediaWiki/SemanticCompoundQueries"

[composer]
mediawiki.SemanticMediaWiki       = "true"

[extdist]
mediawiki.PageForms               = "true"
# ... one line per extdist extension
```

- **`[composer]`** mirrors `process_cargo`: run `composer install` against the already
  resolved git-tag source, capture `composer.lock`, merge into that source's dict. Required
  because **SMW's `composer.lock` is not committed upstream** (verified 404) — the same
  "generate if absent" path cargo takes. SMW's `composer.json` declares
  `"type": "mediawiki-extension"`, 8 runtime deps, and `autoload.files` of
  `src/Defines.php` + `src/enableSemantics.php`.
- **`[extdist]`** is new but trivial: derive the REL branch from the pinned mediawiki version
  (`REL<major>_<minor>` → `REL1_46`), read
  `https://extdist.wmflabs.org/dist/extensions/<Name>-REL1_46-<hash>.tar.gz`, hash it.
  A mediawiki bump automatically retargets extdist — the "for the MW versions we have"
  requirement.

Every extension lands in `sources.nix` as a hashed record, so `update-sources.py --append`
keeps them current with no hand-edited hashes.

### SMW derivation

Copied from `Die-KoMa/mediawiki`'s `packages/default.nix:22-70`, driven by our generated
lockfile:

```nix
# packages/mediawiki-extensions.nix
{ pkgs, lib, system, sources, composer2nix }:
let
  smw = sources.mediawiki.SemanticMediaWiki;
  drv = (import ./smw {
    inherit pkgs system;
    noDev = true;
    composerLock = smw.composerLock;
    src = pkgs.fetchGitTree { inherit (smw) url rev hash date; };
  }).overrideAttrs (_: { dontCheckForBrokenSymlinks = true; });

  base = "${drv}/share/php/mediawiki-semantic-media-wiki";
  json = builtins.fromJSON (builtins.readFile
    (base + "/extensions/SemanticMediaWiki/extension.json"));
in
{
  SemanticMediaWiki = pkgs.stdenv.mkDerivation {
    pname = json.name;
    inherit (json) version;
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir $out
      cp -R ${base}/extensions/SemanticMediaWiki/* $out
      cp -R ${base}/vendor $out/vendor
      pushd $out/vendor/composer/
      substituteInPlace *.json *.php --replace "/extensions/SemanticMediaWiki/" "/"
      popd
      runHook postInstall
    '';
  };
}
```

`composer2nix` has **no `flake.nix`** (verified), so it is `flake = false`:

```nix
composer2nix = {
  url = "github:svanderburg/composer2nix";
  flake = false;
};
```

The NixOS module does `ln -s ${v} $out/share/mediawiki/extensions/${k}`, so each
derivation's **root must be the extension dir**. `fetchzip` strips one root component and
both extdist tarballs and GitHub tag archives satisfy this.

Check `SemanticMediaWiki#6852` (the patch `Die-KoMa` carries) before assuming a plain vendor
copy suffices.

______________________________________________________________________

## lighttpd → nginx

~50 active lines. Full translation:

| lighttpd | nginx |
| --- | --- |
| `var.basedir=/var/www/localhost` | `root = /var/www/html` |
| `indexfiles = (index.php, index.html, …)` | `index index.php index html` |
| `static-file.exclude-extensions = (.php,.pl,.cgi,.fcgi)` | `location ~ \.php$` → `fastcgi_pass` |
| `url.access-deny = ("~", ".inc")` | `location ~ \.inc$ { deny all; }` |
| `/wiki/*` → `/mediawiki/index.php?title=$1` (3 rules + `/wiki$`) | `rewrite` + `location = /wiki` |
| `/mtg_wishlist/api/*` → `index.php`; `/mtg_wishlist/*` → `index.php/$1` | `try_files` block |
| `/momir_basic/api/*` → `src/index.php?$1`, `*` → `public/dist/$1`, `/` → `public/dist/index.html` | `rewrite` block |
| `/kitbash_list/*` → same shape | `rewrite` block |
| `/booktracker/?$` → `/booktracker/public/` | `return 301` |
| booktracker deny `.inc/.json/.sqlite/.php/.log/.lock/.tmp` under `config.json\|data/\|src/\|vendor/\|bin/\|tests/` | `location` + `deny all` |

`services.mediawiki` generates its own vhost with script path `/w`, so the `/wiki` rewrite
must live in a separate `location` ahead of it.

`minifig-tracker` needs the prefix stripped so `Request::path()` sees `/` — an nginx
`fastcgi_param REQUEST_URI` / rewrite, which fixes the 404 without touching app code.

______________________________________________________________________

## Phases

### Phase 1 — sops: encrypt the remaining 7 keys

Move `FLOPPY_SECRET`, `TMDB_API`, `MAL_API`, `IGDB_ID`, `IGDB_SECRET`, `BGG_API_TOKEN`,
`COMICVINE_API`, `GOOGLE_BOOKS_API_KEY` into `secrets/env.json`. Values piped via
`sops set --value-stdin` so nothing lands in a transcript or in `ps`.

**The only phase that reduces live exposure.** Afterwards the remote's plaintext
`/home/monyarm/.nix/.env` can be deleted.

### Phase 2 — `sources.*` extension support

`[composer]` and `[extdist]` sections in `update-sources.py`; `sources.mediawiki.toml`;
`packages/mediawiki-extensions.nix`; the `composer2nix` flake input. Verify with
`update-sources.py --append` and `nix flake check`.

### Phase 3 — new NixOS host `hosts/nixos/monyarm/`

- **Reuse most partitions** per decision. `fileSystems` with the existing UUIDs:
  `LABEL=BOOT` → `/boot` (vfat), `LABEL=Gentoo` → `/` (ext4), `LABEL=MediaSSD` → `/mnt/mediaSSD`,
  `UUID=73d72a40-aab1-417a-96fc-9391676178f6` → `/mnt/HDD`,
  `UUID=f9835d6b-fa62-4696-92ad-408f852afcaa` → `/mnt/Games.old`.
- **`/mnt/Media/store` → `/nix/store` bind-mount is REMOVED.** The store goes on the root
  filesystem; ZFS stays for media only. This decouples the package store from a 3.77T pool.
- `/mnt/HDD/home` → `/home` bind-mount retained.
- **ZFS `media`** — `boot.zfs.enable` + pool import. **Highest-risk item**: a failed import
  means every media-backed service fails.
- systemd-boot + disko, Tailscale, `doas`, the `monyarm` user, headless (`services.xserver`
  off unless needed), Bluetooth, CUPS, avahi.

### Phase 4 — Podman + generated compose

`virtualisation.podman`, compose as a Nix derivation, systemd unit. One-time copy of
`floppy_db` / `redis_data`. Confirm all 5 containers healthy and the four ports respond.

### Phase 5 — nginx + php-fpm

Per-site server blocks and pools; port the rewrites; fix `minifig-tracker`; self-signed 443

- 80→443 redirect; generate the root index.

### Phase 6 — MediaWiki

Run 1.42's `update.php` on Gentoo, import the DB, enable `services.mediawiki` with
`database.type = "sqlite"`, the 12 bundled extensions as `null`, the 19 external ones from
Phase 2's packages, and the `extraConfig` above.

### Phase 7 — sites: source vs state

- Vendored: `army`, `booktracker`, `minifig-tracker`, `mtg_wishlist`, `V5`.
- Runtime data under `/var/lib/monyarm-web/` and `/mnt/Media/`:
  `kitbash_list` (4.8G / 24 DBs), `momir_basic` (4.5G), `mediawiki` state. Recorded in `TODO.md`.

### Phase 8 — host services

`syncthing` (rebuild the 4 folder declarations; back up `key.pem` first or peers
re-handshake), `jellyfin`, `mysql`/`mariadb` dump/restore, `libvirtd` + the 2 VM XMLs,
`qemu-binfmt`.

### Phase 9 — verify, then decommission

Same ports listening, each site at its expected status, containers healthy, MySQL accepting
logins, syncthing in sync, ZFS online with matching `used`.

______________________________________________________________________

## Risks

1. **ZFS `media`** — losing it breaks every media-backed service. Back up
   `zfs list -o name,mountpoint,used` and verify pool import before cutover.
1. **MediaWiki 1.42→1.46 + SMW 5.0.0→7.3.0** — the largest jump. Back up
   `mediawiki.sqlite` (13.7MB) before every bump; the migration is non-atomic and a failing
   `mediawiki-init` does not stop php-fpm.
1. **MySQL data** — hand-rolled root credentials, `mariadb.d` config not in the repo.
   Explicit dump/restore; password to sops.
1. **Syncthing identity** — losing `key.pem` re-trusts every peer.
1. **Mutable checkouts** — sites run from dirty trees with 8.1M `debug.log` files. Building
   them in Nix may surface undeclared dependencies.
1. **`composer2nix` against a lockfile-less upstream** — SMW's deps resolve at update time,
   so pin behaviour with the generated `composer.lock` in `sources.nix`.
1. **Partition reuse** — reusing UUIDs means a bad `fileSystems` entry can target the wrong
   disk. Verify by UUID before any destructive step.

## Open decisions

- Which host services to drop: `jellyfin` (8096), `libvirtd` + 2 VMs, headless Steam,
  `cupsd`, `avahi`, `mysql`. If MySQL goes, `minifig-tracker` should switch to SQLite
  permanently — `Database.php` already has that branch.
- Are `ExternalData` / `DataTransfer` / `PageForms` still live, or legacy from the
  "Miniature Compendium" era? Dropping unused ones shrinks the Phase 2 work.

## Out of scope

`cardconjurer`, `CookieClicker`, `test/`, pure-Nix reimplementation of the 4 containerised
apps, per-army HTML page generation (Blood Ravens has a real page in `archive.7z` to port
later), vendoring `kitbash_list` / `momir_basic` / `mediawiki` state, and the 2 libvirt VMs'
OS installs (only their definitions move).

## TODO.md additions

Per site: data location, DB path, vendored-vs-runtime. Plus the 8.1M `debug.log` files, the
`T'au` leftovers, the dangling `cardconjurer` symlink, and the currently-broken wiki and
`minifig-tracker`.
