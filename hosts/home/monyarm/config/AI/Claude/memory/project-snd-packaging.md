---
name: project-snd-packaging
description: "Package snd (Sales & Dungeons) into the repo: sources.ttrpg.toml + packages/snd.nix wiring, new generic [npm] options in update-sources.py (subdir/freshlock/forcegitdeps), packages/nunjucks-fork.nix, working build + CUPS print (blank sheets fixed by 24-row re-banding in tp.py), and packages/snd-workshop.nix importing 92 BigJk/nbadal/frshbeetz/Elfenspalter packages"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T19:17:42.859Z
---

Ongoing work (as of 2026-11-16): package https://github.com/BigJk/snd ("Sales & Dungeons", Go + Svelte frontend, thermal-printer TTRPG tool) into the repo, declaratively ship its "workshop" content, and test it against the DP-L1S thermal printer.

State:
- New `sources.ttrpg.toml`: `[git-tag] ttrpg.snd` + `[npm] ttrpg.snd = "true;subdir=frontend;forcegitdeps"` (only `frontend/` has package.json), plus a separate entry for the nunjucks git fork.
- `packages/snd.nix`: `buildGoModule` for `cmd/app` with CUPS/libusb, wrapped with cwd/userdata/`SND_CHROME_BIN`/CUPS PATH; frontend via `buildNpmPackage` on `${src}/frontend`.
- `update-sources.py` gained three *generic* `[npm]` options (not one-off hacks): `subdir=` (monorepo package dir), `freshlock` (regenerate package-lock.json from scratch so deps keep `resolved` URLs), `forcegitdeps` (git deps without lockfile entries, maps to `forceGitDeps`).
- S&D prints through CUPS as raw data to a named printer (`printing/cups/cups.go`), matching this repo's raw-queue setup; it emits a single `GS v 0` raster per page, which the printer drops unless the receiver re-bands it (that split now lives in `packages/tp.py`).
- Resolved blocker (2026-11-16, on the user's suggestion): the frontend depends on git fork `ogonkov/nunjucks#fix_async_extensions_parse`, whose `main: index.js` is *generated* by its `prepare` script, and nixpkgs' npm hook always runs `npm ci --ignore-scripts`. Chosen approach: add the nunjucks fork as its own `sources.ttrpg.toml` entry with a custom package `packages/nunjucks-fork.nix` (builds it with its prepare script), then use that package in snd instead of letting npm fetch the fork. (Rejected: swapping in registry `nunjucks@3.2.4`, losing the async-extensions patch; upstream's published `snd-frontend.zip` dist remains a fallback.)
- 2026-11-16: build completed and the packaged snd runs from the store (`…-snd-v1.4.0/bin/.snd-wrapped`, v1.4.0 / commit ba14f2a). Serving initially 404'd until the run dir had the `frontend` + `data` store symlinks (plus writable `userdata`); after that `GET /` returns 200.
- 2026-11-16: S&D's own print API submits CUPS jobs that CUPS reports as completed but the sheets came out blank; root cause was the printer dropping the single over-tall raster, fixed by re-banding in `tp.py` and confirmed on paper via a direct backend test (user: "printed fine"). A live `/api/print` through the real queue still needs a `./deploy.sh` so CUPS picks up the new `tp` store path (as of 2026-11-16 the ServerBin backend is still the pre-fix path).
- Workshop content: user picked the BigJk, nbadal, frshbeetz and Elfenspalter repos (not the michaelkleinhenz or Lavaill ones). Nine `[git]` entries under `ttrpg.workshop` in `sources.ttrpg.toml` (snd-default-templates, snd-bigjk-templates, snd-open5e, snd-srd-bestiary, snd-bfrpg-monster, snd-nbadal-templates, snd-EVT-templates, SalesAndDonkeys, SD_MoSh), all tracking main since the repos are unmaintained; resolved with `./update-sources.py ttrpg.workshop`.
- `packages/snd-workshop.nix` lays the 9 repos out at `share/snd-workshop/<repo>/<package-folder>/` and provides `bin/snd-import-workshop`, which POSTs each package folder trying `importsTemplateFolder` → `importsSourceFolder` → `importsGeneratorFolder` (upstream's type-detection order from `git/repo.go`); idempotent, `SND_URL` defaults to `http://127.0.0.1:7123`.
- Verified against the live instance 2026-11-16: 92 packages imported → `getTemplates: 30`, `getSources: 28`, `getGenerators: 33`. Only `scripts/` in the BigJk repo was skipped (not a package folder).
- Gotcha: the import RPC body must be *nested*, `[["<path>"]]`; `[[path]]` returns 400 `mismatching argument type of 1. argument. got=string expected=slice` and silently imports nothing.
- Deliberately not done: no auto-seeding on snd startup (would mutate the user's DB unasked) and no system-package entry for `snd-workshop`. 18 files staged, nothing committed yet.

**How to apply:** Remaining work as of 2026-11-16: `./deploy.sh` so CUPS picks up the new `tp` store path, then a live `/api/print` re-test; plus committing the staged files on the user's say-so. Don't re-derive the TOML/`[npm]`/fork-package/cwd-symlink/band-split/workshop-import work already done. When an existing sources entry's generated data (hashes, lockfiles) changed, regenerate with a dotted selector (`./update-sources.py ttrpg`), not `--append` — `--append` only adds entries missing from `sources.nix` and would carry stale values over.
