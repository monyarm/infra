---
name: per-engine-sources-toml
description: User prefers a dedicated sources.<engine>.toml holding all of one engine's sources (git tag + asset zips) instead of scattering entries into sources.tools.toml
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-13T18:15:40.309Z
---

When a new engine/tool needs several sources, put them together in a dedicated `sources.<engine>.toml` (e.g. `sources.trx.toml` with both `[git-tag] trx.engine` and `[zip] trx.assets.*`) rather than adding entries to `sources.tools.toml` or another existing manifest — the user proposed this directly ("probably best place to put it all would be a sources.trx.toml, with the zips and git repo in there").

**Why:** Keeps one engine's sources in one place, matching existing per-area files like `sources.mpv.toml`, `sources.scummvm.toml`, `sources.claude.toml`.

**How to apply:** Check whether the area already has its own `sources*.toml` first; if adding a new one, no registration edit is needed (the loader globs `sources*.toml`), and a prefix selector such as `./update-sources.py trx` refreshes every entry in it. Note that `update-sources.py` rewrites all of `sources.nix` regardless, so compare semantics rather than the diff.
