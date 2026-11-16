---
name: no-du-whole-nix-store
description: Never walk, list, grep or glob /nix/store or / wholesale — resolve the exact path via nix instead.
metadata:
  type: feedback
  modified: 2026-11-16T17:17:33.508Z
  updatedBy: opencode
---

Never run `du -sh /nix/store`, `find / ...`, `find /nix/store ...`, `ls /nix/store | grep ...`, or a shell glob like `/nix/store/*tp*` — any whole-store or whole-filesystem expansion to "see what's there" or locate a package's store path.

**Why:** `/nix/store` and `/` are enormous; a full walk takes forever or hangs, and the user considers this an obvious, infuriating mistake. Corrected sharply multiple times across sessions for the same category of command — including `find / -maxdepth 6 -iname '*crane*' -path '*store*'` (looking for a flake input's store path), a `find -maxdepth 4 -iname '*.ttf'` that hung 2 minutes, an `ls /nix/store | grep -i fonttools`, and a glob in `/nix/store` during the 2026-11-16 thermal-printer testing ("YOURE NOT ALLOWED TO GLOB IN THE NIX STORE"). `-maxdepth` does not save you: `/nix/store` is a flat directory of hashed paths, so any depth-limited find still enumerates every top-level entry first; piping to grep doesn't narrow it either since `ls`/`find` must produce the full listing before the pipe filters it. Globbing is the same enumeration under another name and is equally off-limits.

**How to apply:** Never derive a store path by searching or globbing for it — resolve it directly:

- Free disk space: `df -h /` (or the relevant mount), not `du`.
- "Is this derivation built/cached?": `nix path-info <installable>` or `nix build --dry-run`.
- A built output's store path (e.g. to confirm which `tp` a queue points at): `nix eval --raw .#<attr>` / `nix build --print-out-paths`, never a glob over `/nix/store`.
- A flake input's store path/rev: `nix flake metadata --json` (or `flake.lock` directly) for the locked rev, then fetch/inspect that specific ref (e.g. `nix eval`/`WebFetch` against the pinned commit) — not `find /nix/store` for a directory name that happens to match.
- A specific file's contents inside a known derivation: build/eval that exact attribute and read from its resolved `out` path, never scan for it.

**Subagents don't inherit this automatically.** A dispatched Explore/general-purpose agent has no view of this rule and will happily `grep -r`/`find` across `/nix/store` if asked to "search nixpkgs source for X" — caught doing exactly this while researching package attributes. Any subagent prompt that touches nixpkgs internals must explicitly restate the constraint (e.g. "resolve exact store paths via `nix eval`/`nix search`, never grep/find/ls/glob the whole `/nix/store`").
