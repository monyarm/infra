---
name: project-light1-games-leak-root-cause
description: "Resolved 2026-11-16: LIGHT=1 still pulled openxcom-extended/realrtcw/tombraider-trx in because hosts/modules/packages/optimize.nix GC-roots every packages/* derivation; runtime engines are now excluded from that root list"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T00:00:00.000Z
---

With `LIGHT=1` all games are supposed to be disabled, yet a deploy drift showed `openxcom-extended`, `realrtcw`, `tombraider-trx` (plus SDL_gfx/SDL_image/SDL_mixer/sdl12-compat/libopenmpt-modplug, ffmpeg 8.1.3) added to the system closure.

**Root cause:** `hosts/modules/packages/optimize.nix` writes `xdg.dataFile."nix-roots/optimize"` containing a GC root for **every derivation named after a file in `packages/`** (`localPackages`), so those store paths are pulled into the home generation regardless of whether any game is enabled. The game modules themselves were correct: with `LIGHT=1`, `games.{rtcw,trx,openxcom}.enable=false` and `programs.steam.games=[]` in both the standalone home config and the NixOS home-manager user.

**Fix (2026-11-16):** an `enginePackages = [ "openxcom-extended" "realrtcw" "tombraider-trx" ]` list subtracted from `localPackages` in that file, so runtime engines are rooted only through their enabled game entries. Verified by evaluating the roots text with `LIGHT=1`: `leaked = []`, `tpRooted = true`.

**Why:** the root list exists to keep build-time pipeline tools (extractors, fetch helpers) from being GC'd, not to root runtime game engines — engines belong to the games that enable them.

**How to apply:** a new custom runtime engine added under `packages/` must be added to `enginePackages`, or it will reappear in every generation including `LIGHT=1` ones. Pipeline/extractor tools stay rooted automatically.
