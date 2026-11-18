---
name: reference-engine-nixpkgs-vs-upstream-versions
description: Verified 2026-11-17 comparison of pinned-nixpkgs versions against upstream tags for the game-engine/reimplementation set (incl. openjk bundling JK2 SP, arx-libertatis 1.2.1, yquake2 8.60, R.E.L.I.V.E. absent with no SPDX licence), plus library availability notes
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T23:46:52.775Z
---

Verified 2026-11-17 against the pinned nixpkgs (`13e53762c5af…`, lastModified 1793795574).

**Current in nixpkgs — no override needed:** `wargus`/`stratagus` 3.3.2 (= upstream v3.3.2), `opentyrian` 2.1.20260913 (= upstream), `gemrb` 0.9.5 (= upstream v0.9.5), `arx-libertatis` 1.2.1 (= upstream tag 1.2.1, so Arx Fatalis is a data-only job), `yquake2` 8.60 (= current upstream Yamagi Quake II), `openjk` 0-unstable-2026-09-29 (upstream tags are only `latest` and `v0.0.0`, so a dated unstable is the right shape).

**OpenJK specifically:** pinned `openjk` already sets `BuildJK2SPEngine`/`BuildJK2SPGame`/`BuildJK2SPRdVanilla` true, i.e. Jedi Outcast singleplayer ships in the same derivation as Jedi Academy — no separate package or build configuration needed.

**In nixpkgs but lagging:** `openrct2` 0.5.6 vs upstream v0.5.7 → use `fetchGitTree` + `overrideAttrs` (same pattern as Dark Forces does for `theforceengine`). `freedink` 1.08.20190120 — upstream version still unverified, likely stale.

**Absent from nixpkgs (need a real derivation):** `war1gus` (upstream v3.3.2), `keeperfx` (upstream v1.4.0, released 2026-07-04), `openjkdf2` (v0.9.9), `mkxp-z` (v2.4.2), `ags` (v3.6.0.48), `stratagus` as a top-level attribute (only nested inside `wargus`), and **R.E.L.I.V.E.** (GitHub `AliveTeam/alive_reversing`, "Re-implementation of Oddworld: Abe's Exoddus and Abe's Oddysee", ~456 stars, last push 2026-10-26) — note it exposes **no SPDX licence id**, so its `LICENSE` must be read before packaging.

**Library availability checked the same day:** present — `sdl3` 3.4.18, `sdl3-image` 3.4.8, `sdl3-mixer` 3.2.4, `libspng` 0.7.4, `enet` 1.3.18, `p7zip` 17.06. Absent — `luajit`, `7zz`, `stratagus`.

**Why:** the user's standing rule is to vendor an engine through `sources.*.toml` + `fetchGitTree` when nixpkgs lags or is missing, so this table decides per-engine whether a package is "reuse nixpkgs" or "own derivation".
**How to apply:** re-check before relying on it — versions drift; attribute names were confirmed by lookup in the pinned nixpkgs, not by evaluating a full build.
