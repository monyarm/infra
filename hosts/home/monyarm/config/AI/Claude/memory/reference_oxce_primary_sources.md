---
name: reference-oxce-primary-sources
description: Where to research OpenXcom Extended (forum topic 5258, openxcom.org/oxce/release, mod.io, ModDB) and its Nix-packaging gotchas
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-13T17:04:42.967Z
---

OpenXcom Extended (OXCE), the X-COM engine planned for this repo, is researched from these primary sources:
- github.com/MeridianOXC/OpenXcom, branch `oxce-plus` — source, `CMakeLists.txt`, `bin/TFTD/README.txt`; the GitHub REST API confirms the branch tip but **there are no OXCE releases/tags** (tags stop at the 2014 fork point, v1.0).
- github.com/OpenXcom/OpenXcom — legacy upstream (1.0 milestone 2014-06-13, nightlies only, maintenance-mode commits).
- openxcom.org/oxce/release/ plus the openxcom.org forum thread `topic,5258` — the actual OXCE release channel (version + build date live in the thread's first post).
- openxcom.org/downloads/ — retail-data requirements and "do not use XcomUtil-modded data" notes; openxcom.org 2026-01-12 post "What's the deal with OpenXcom Extended?" (OXCE is the recommended engine, OXC legacy).
- openxcom.mod.io (mod listings/downloads, API needs a key) and ModDB (large overhaul mods such as X-Piratez).

Packaging-relevant notes from that research (as of 2026-11-13, OXCE v8.7.1):
- Linux build is CMake ≥3.5 / C++17 with SDL 1.2 (+ SDL_image/SDL_gfx/SDL_mixer 1.2) and zlib; since 8.0 RapidYAML + miniz are vendored, so **yaml-cpp is no longer a dependency**. Upstream only "officially supports" Windows builds.
- Runtime switches `-data`, `-user`, `-config`, `-master`; user dir `$XDG_DATA_HOME/openxcom` (else `~/.local/share/openxcom`), config in `$XDG_CONFIG_HOME/openxcom`, mods under `<user>/mods`; datadir baked via `INSTALLDIR`/`-DDATADIR`.
- Retail data is user-supplied only; mods are mostly unlicensed third-party art, so they are not redistributable and only versioned URLs can be hash-pinned (forum attachments and mod.io zips are replaced in place). Mod↔engine versions are coupled (8.0 YAML strictness, save format), and some mod archives bundle a Windows `openxcom.exe` that must be stripped.
