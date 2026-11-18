---
name: project-book-keeper-gemmaker-packaging
description: 2026-11-16 packaging of the user's own TTRPG loot generators monyarm/Book-Keeper and monyarm/GemMakerDnD (sources.ttrpg.toml entries + packages/book-keeper.nix, packages/gemmaker.nix), plus the 2026-11-17 upstream GemMakerDnD CLI bugs the user reported
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T22:45:59.350Z
---

2026-11-16: packaged the user's own TTRPG loot/table generators — https://github.com/monyarm/Book-Keeper (random D&D loot books, plus a JSON book database from many fiction sources) and https://github.com/monyarm/GemMakerDnD (random gems) — as `packages/book-keeper.nix` and `packages/gemmaker.nix`, with source entries in `sources.ttrpg.toml`.

Status: both built and smoke-tested 2026-11-16 (`book-keeper random 3` printed real book data from the pinned Book-Keeper-Data source; `gemmaker --random 3` produced gems) and both are now listed in `hosts/modules/packages/apps.nix`, so the `book-keeper` / `gemmaker` commands land on PATH at the next deploy.

Notable repo shapes discovered:
- Book-Keeper is a TypeScript CLI (`books` / `sources add|remove|list|sync` subcommands) whose book data lives in a separate repo, `monyarm/Book-Keeper-Data`; it clones/reads sources under `~/.book-keeper`.
- GemMakerDnD ships its data in-tree (Anime / Book / Cartoon / Comic / Movie / Real Life / TV / Tabletop Game / Video Game / Web dirs plus `convert.js`), so it needs no second fetch.

2026-11-17: user reported "your gemmaker wrapper is broken". Verified the nix wrapper is fine (PATH, NODE_PATH resolving lodash + minimist, store bin at `...-gemmaker-1.0.0/bin/gemmaker`); the defects are in upstream `cli.ts`:
- Any invocation without `--random`/`--log` prints nothing and exits 0 — filters are applied but no `console.log` path is reached, so `gemmaker --type Diamond`, `-t Maxixe`, `gemmaker Diamond` are silent.
- Bare `gemmaker random 3` prints 1 gem instead of 3: the code only reads the count when `args.random === true` (`args.random === true ? args._[randomIndex + 1] : args.random`), so bare `random` leaves it undefined → count 1. `--random 3` / `--rand 3` work.
Filters, `-v/-c/-cr`, and `--log` (25 gem types / 11352 variations) all work. Two proposed fixes were put to the user: `postPatch` on `cli.ts` in the derivation, or fix upstream in monyarm/GemMakerDnD and bump the source. User had not chosen as of the transcript end.

**Why:** both are the user's own projects and the direct peers of the TTRPG-CLI survey they asked for (see reference-ttrpg-cli-content-generators).

**How to apply:** treat `sources.ttrpg.toml` as the home for TTRPG tool sources (per prior preference for per-engine sources files) and remember Book-Keeper's data repo is a separate fetch, not part of the app source. If the user reports a packaged CLI misbehaving, check whether the wrapper or upstream CLI is at fault before patching the derivation.
