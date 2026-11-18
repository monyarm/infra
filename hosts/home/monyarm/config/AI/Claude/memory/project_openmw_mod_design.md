---
name: project-openmw-mod-design
description: "2026-11-17: user approved the ordered games.openmw.mods list with data-dir + plugin management; plan written to /home/monyarm/.opencode/plan/openmw.md, with data-dir precedence and no-MWSE-Lua left as open/flagged points"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T23:55:32.369Z
---

2026-11-17: the user delegated OpenMW (Morrowind) packaging design to the agent, "cause it'll be much more complicated due to the mod support", then **approved** the proposed shape: "that openmw suggestion works well, ordered list, data dir and plugin management". The plan is written at `/home/monyarm/.opencode/plan/openmw.md` (nothing implemented yet).

Approved design:
- The awkward part is not the engine (nixpkgs `openmw` is mature) but OpenMW's mod model: ordered data directories plus an explicit plugin load order, expressed as `data=` / `fallback-archive=` / `content=` lines in `openmw.cfg`. Line order gives precedence, so no conflict-merge logic is needed.
- `games.openmw.mods` as an **ordered list** (order is semantic), each entry `{ name, src, plugins ? null }`.
- `openmw.cfg` generated at build time: base game `data=` lines first, then each mod dir in list order, a `fallback-archive=` per `.bsa`, then `content=` from base ESMs followed by each mod's plugins.
- `plugins = null` auto-detects `.esm`/`.esp` and sorts them; an explicit list overrides it (needed for ordered patches).
- Generated cfg is copied into `$XDG_DATA_HOME/openmw` only when its hash changes; launch with `--config` / `--user-data` so saves/settings stay writable and the store stays read-only.
- Data source: Steam `22320` or GOG `the_elder_scrolls_iii_morrowind_goty` (GOTY includes Tribunal/Bloodmoon).

Flagged in the plan rather than assumed: (1) whether OpenMW resolves data dirs first-wins or last-wins — a two-mod texture test decides it and the generation order flips if needed; (2) MWSE Lua mods are not supported, only OpenMW-Lua.

Version: nixpkgs `openmw` 0.51.0 matches upstream stable (`openmw-0.51.0`, 2026-06-19); only `openmw-52-rc1` is newer, so no source override needed.

**Why:** the user reviews and approves designs before implementation, so the approved decisions are the contract for the plan.
**How to apply:** implement from these approved choices; do not re-ask the list-vs-attrset or auto-detect questions, and keep the data-dir precedence question open until the two-mod test is run.
