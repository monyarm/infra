---
name: nix-repo-notes
description: Background knowledge about this Nix flake repo's tooling and hard-won gotchas around dynamic derivations, derivation naming, and the bundled Python scripts. Not user-invocable; read automatically for context on nix build/eval work in this repo.
user-invocable: false
---

# Repo-specific Nix notes

## Bundled scripts (use these, don't reinvent them)

- **`measure-compression.py`** (repo root) — builds every registered Doom WAD/ScummVM game twice (real pipeline vs. `optimize`/`removeFiles`/`compressScummvmGame` force-mocked to passthrough) and records before/after sizes in `compression-savings.csv`. Use this for any "did my optimize/cruft-removal change actually save bytes" question instead of hand-rolling a `du -sb` comparison.
  - `./measure-compression.py <name-substring>...` — filter by game name
  - `./measure-compression.py --list [--missing]` — list available game names
  - `./measure-compression.py --scummvm` / `--doom` — restrict to one category
- **`update-sources.py`** (repo root) — fetches/tracks itch.io, GOG, and mod-site source versions into `sources.nix`/`sources.toml`. The `version` field it records for itch sources is a multi-upload change-detection fingerprint (joins every upload's `id:md5:timestamp` on the game's page, not just the selected one) — it's meant for *this script's* staleness comparison, not for Nix-side derivation naming (see below).
- **`build-retry.sh`** (repo root) — retries a nix build command, handling flaky remote-builder/network fetches (Steam/GOG credentials etc). When looping it over a whole registry of games, the drv path must be re-resolved *fresh inside the retried command itself* (e.g. via a nested `nix eval --raw ... | nix build ...`), not computed once upfront — otherwise a hash `build-retry.sh` patches mid-loop won't be picked up on retry, since the stale pre-resolved path keeps getting rebuilt.

## Formatting and file tracking

- `nix fmt -- <file>` is this repo's formatter entrypoint (treefmt wrapping nixfmt/deadnix/statix, configured in `flake.nix`). A hook already runs this automatically after Claude edits/writes any `.nix` file — no need to run it manually.
- New `.nix` files are invisible to `builtins.getFlake` until `git add`ed, causing confusing "attribute missing" errors on otherwise-correct code. A hook already runs `git add` automatically after Claude creates a new `.nix` file via Write.
- Before starting any `nix build`/`nix eval`, check nothing else is already running (`ps aux | grep nix` / `pgrep -x nix`) — this machine is RAM-constrained. A PreToolUse hook already warns on this for Bash commands containing `nix build`/`nix eval`/`nix-instantiate`.

## Dynamic derivations (`lib/optimize/`, `compressScummvmGame`, anything using `builtins.outputOf`)

This repo's `lib/optimize/` machinery (and anything built on top of it, like `compressScummvmGame`) uses Nix's experimental dynamic-derivations feature (`builtins.outputOf`) to do per-file folder optimization at build time. This has real, sharp-edged tooling gaps:

- **`nix build --expr` on an attrset of multiple such paths silently does nothing** — no error, no build, just warnings. Build one bare expression at a time instead: `nix build --impure --no-link -L --print-out-paths --expr '(builtins.getFlake (toString ./.)).homeConfigurations.<name>.config.<path>.path'`.
- **A registered `path` that's a narrowed subpath of a dynamic derivation** (e.g. `"${someGame}/DATA"`) **can fail to build via `nix build --expr` even as a bare (non-attrset) target**, with an error like `the string is not the right placeholder for this derivation output. It should be '<other-path>'`. This is a real CLI limitation, not a sign the underlying derivation is broken — Nix's own error message tells you the correct buildable placeholder (the same string *without* the subpath suffix); build that directly to confirm the underlying derivation is sound.
- **The cheap "does this eval soundly without a full build" trick** — `nix eval --impure --json <expr> --apply 'g: builtins.attrNames (builtins.getContext g.path)'` to pull the underlying `.drv` path out of a string's build context, then `nix path-info <drv>^out` to resolve it — **breaks once a dynamic derivation is anywhere in the chain**, erroring with `cannot operate on output 'out' of the unbuilt derivation`. Once `optimize`/`compressScummvmGame` is involved, just eval the plain `.path` string directly instead (still cheap — Nix won't force a build just to print an unresolved CA/dynamic placeholder string — but skip the `getContext` step).
- `pgrep -f '<pattern>'` inside a hook or verification script **can match its own invocation** if the pattern text itself appears in the command line being searched (e.g. a `bash -c "...pgrep -f 'nix build'..."` subshell's own cmdline contains the literal string "nix build"). Prefer `pgrep -x <short-process-name>` (e.g. `pgrep -x nix`) over `-f` with a pattern that echoes back into its own invocation.
- **`nix-store -q --outputs <drv>` fails on anything downstream of a dynamic derivation** with `Cannot use output path of floating content-addressing derivation until we know what it is` — a plain, non-`__contentAddressed` wrapper derivation (e.g. a symlink wrapper around one of these paths) still becomes an unresolvable "floating" output the moment any of its inputs is a `builtins.outputOf` chain, since Nix can't compute an input-addressed output-path hash around an unresolved placeholder. There's no way to learn the output path ahead of building; you have to build it (`nix build ...^out --print-out-paths` or `--json`) and read the path back from that.
- **A single multi-target `nix build a^out b^out ... --print-out-paths` (or `--json`) prints *no* output paths at all — not even for targets that succeeded — the moment any one target in that same invocation fails**, `--keep-going` included. Confirmed empirically (measure-compression.py's build_batch/build_one, 2026-08-11): building N games' targets in one invocation is an all-or-nothing reporting boundary. If per-target success/failure needs to survive a partial failure, launch one `nix build <drv>^out` subprocess per target instead (concurrently, via a thread pool is fine) rather than handing the whole batch to a single invocation — the nix daemon's own job-slot admission still paces the real concurrency across separate client processes exactly like it would within one multi-target call.

## Derivation naming

`sanitizeName`/`getName` (`lib/strings.nix`) are re-derived at every pipeline stage, and each stage appends its own suffix (`-pruned`, `-scummvm-compressed`, `-optimize-instantiate.drv`, ...). Some sources produce names that are already 150+ characters on their own (itch's multi-upload fingerprints, before the fix that stopped embedding `version` in `fetchItch`'s `name`) — stacking several stages' suffixes on top can blow past Nix's 211-character derivation name limit several stages in, with an opaque `invalid derivation name` error. `sanitizeName` truncates to 100 chars for exactly this reason; if you're inventing a *new* naming scheme anywhere in this repo's fetchers/pipelines, don't bypass it.
