______________________________________________________________________

## name: no-du-whole-nix-store description: Never walk /nix/store or / wholesale (du/ls/find) — resolve the exact path via nix instead. metadata: node_type: memory type: feedback originSessionId: dd2c7cec-fbaa-4c55-bdcb-f638f1c66e5f

Never run `du -sh /nix/store`, `find / ...`, `find /nix/store ...`, or `ls /nix/store | grep ...` — any whole-store or whole-filesystem walk to "see what's there" or locate a package's store path.

**Why:** `/nix/store` and `/` are enormous; a full walk takes forever or hangs, and the user considers this an obvious, infuriating mistake. Corrected sharply multiple times across sessions for the same category of command — including `find / -maxdepth 6 -iname '*crane*' -path '*store*'` (looking for a flake input's store path), a `find -maxdepth 4 -iname '*.ttf'` that hung 2 minutes, and an `ls /nix/store | grep -i fonttools`. `-maxdepth` does not save you: `/nix/store` is a flat directory of hashed paths, so any depth-limited find still enumerates every top-level entry first; piping to grep doesn't narrow it either since `ls`/`find` must produce the full listing before the pipe filters it.

**How to apply:** Never derive a store path by searching for it — resolve it directly:

- Free disk space: `df -h /` (or the relevant mount), not `du`.
- "Is this derivation built/cached?": `nix path-info <installable>` or `nix build --dry-run`.
- A flake input's store path/rev: `nix flake metadata --json` (or `flake.lock` directly) for the locked rev, then fetch/inspect that specific ref (e.g. `nix eval`/`WebFetch` against the pinned commit) — not `find /nix/store` for a directory name that happens to match.
- A specific file's contents inside a known derivation: build/eval that exact attribute and read from its resolved `out` path, never scan for it.
