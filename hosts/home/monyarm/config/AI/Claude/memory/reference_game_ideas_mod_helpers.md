---
name: reference-game-ideas-mod-helpers
description: "GAME_IDEAS.md has proposed-but-unbuilt mkModDir/wrapGame helpers for the \"many derivations need to land at named paths inside one game/mod folder\" shape — check before designing a new per-game mod-symlinking mechanism."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 913da512-b3a2-443b-bc56-75b3633c275e
---

`GAME_IDEAS.md:7-27` sketches two cross-cutting `lib/` helpers, explicitly "proposed, not designed yet... worth a real design pass once more than one entry actually needs them":

- **`mkModDir`** — takes a game dir derivation plus an attrset `{ "path/inside/mod/dir" = drv-or-list-of-drvs; ... }`, produces the merged mod-directory tree. Covers "many separately-fetched derivations need to land at specific named paths inside one folder" (Ikemen `chars/<name>/`, SuperTuxKart `addons/{karts,tracks}/<name>/`).
- **`wrapGame`** — takes a game derivation plus a list of folder paths, produces a wrapper that mounts/symlinks those paths to the engine's expected runtime location (e.g. `~/.local/share/<engine>/`) before launching.

**Why this matters:** any new per-game mod/addon-loading design (Ren'Py's `mods = []`/`modDir`, or any future engine module) is a narrower special case of this exact shape. Don't redesign mod-symlinking from scratch — check whether it's simple enough to stay local (a flat list + one destination, as with Ren'Py) or whether it's the second real consumer that justifies actually building the general `mkModDir`/`wrapGame` helpers GAME_IDEAS already sketched.

**How to apply:** when a game module needs "symlink N derivations into specific subpaths of a game dir" or "point an engine's fixed runtime path at a Nix-built folder," read `GAME_IDEAS.md:7-27` first.
