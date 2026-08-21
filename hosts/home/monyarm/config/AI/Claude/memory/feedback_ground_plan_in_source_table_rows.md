---
name: ground_plan_in_source_table_rows
description: "When user gives a list of engine names plus a prior research file, map each engine to the file's exact game rows instead of re-listing engines abstractly."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9708f884-1b63-479f-8e37-5be315ad2881
---

When the user asks to add entries for a list of engines/tools (e.g. "add KeeperFX, OpenRCT2, ...") and points at a prior research file (e.g. `game-candidates.md`) that already did the games.list-to-engine matching, ground every plan item in that file's exact rows (games.list id, source, existing caveats) — don't restate the engine list generically as if game selection were still open. The file already answered "which owned game maps to which engine"; re-deriving it is redundant and can silently drop rows or caveats.

**Why:** Corrected mid-plan-mode when a plan enumerated "17 candidate engines" without citing which specific owned game(s) each mapped to, even though `game-candidates.md` had that mapping (with games.list ids and per-row caveats) sitting right there.

**How to apply:** Read the source file fully before drafting the games-to-add list. For each engine, cite the exact row(s): games.list id, Steam/GOG source, and any caveat already flagged (WIP, EE-data-compat uncertain, etc.) — carry the caveat into the plan rather than dropping it. When a source-table one-line note makes a strong claim ("already ships upstream, not a port to do"), treat it as a research target to verify, not settled fact — especially for multi-engine-to-multi-game situations (e.g. Build engine: eDuke32 vs Raze vs VoidSW mapped across two different owned titles, not a uniform three-way choice for one game). See [[feedback_source_list_first_then_intersect]] for the related "pull the external list first" habit this extends.
