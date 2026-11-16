---
name: feedback_no-fetcher-type-comments-in-toml
description: Never add comments in sources*.toml explaining that an entry is "[git], not [git-tag]" — the section heading already says it; only comment external non-obvious facts
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-13T18:55:50.145Z
---

Do not add comments to `sources*.toml` explaining which fetcher an entry uses, e.g. `# [git], not [git-tag]` or a note about why `[git-tag]` was not chosen.

**Why:** the user cut these out directly — "those are some bad comments, '[git], not [git-tag]', why would you add those comments!?" The `[git]` / `[git-tag]` / `[zip]` section heading is already the fetcher declaration, so such a comment only repeats the line and records the reasoning/decision history that belongs in the plan file, not in the config.

**How to apply:** leave the TOML line bare. Keep a comment only for a fact a reader cannot see from the entry itself and needs before editing it — e.g. "no tags upstream (pre-alpha) -- HEAD pin", "default branch is already oxce-plus, so no branch needed". Never comment the fetch-type choice or anything that reads as development history.
