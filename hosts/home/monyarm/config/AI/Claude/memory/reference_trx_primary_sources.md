---
name: reference-trx-primary-sources
description: "Where to research TRX: GitHub repo/releases API, docs/trx/*.md (CLI, gameflow, building), lostartefacts.dev, trcustoms.org"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-13T17:06:37.224Z
---

TRX (LostArtefacts), the Tomb Raider I–III reimplementation planned for this repo, is researched from these primary sources:
- github.com/LostArtefacts/TRX — README (install/layout instructions), `/releases` and the GitHub REST API `/repos/LostArtefacts/TRX/releases` for exact tags/dates/asset names, and `docs/trx/*.md` (README, CLI options, game flow spec, level reference, music track IDs, injections, USER_CONFIGURATION). Build docs are `docs/BUILDING.md` and `docs/BUILDING_ON_LINUX.md` (top-level BUILDING.md is 404) — Linux path is Docker + `just` (deps SDL2, GLEW, FFmpeg/libav, libpcre2, Lua, zlib, GL).
- lostartefacts.dev — project site (`/trx/`, `/trx/docs/`) with the feature tour.
- trcustoms.org — custom-level host (`levels/<id>`, walkthrough pages, download sizes); trle.net mirrors the classic scene.
- TRX ships official Linux release artifacts (`TRX-1.12-Linux.zip`, ~361 MB, includes `cfg/` + `games/` ship assets), so packaging does not require building from source.
