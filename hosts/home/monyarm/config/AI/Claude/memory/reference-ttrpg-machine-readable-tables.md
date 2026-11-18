---
name: reference-ttrpg-machine-readable-tables
description: Where to find TTRPG random tables/stat data in JSON/CSV/YAML form for a CLI to consume (5e-database, lorebench-tables, datasworn, autorolltables)
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T21:17:37.342Z
---

Verified 2026-11-16, for feeding a CLI generator (e.g. Book-Keeper-style JSON data sources):
- 5e-bits/5e-database — github.com/5e-bits/5e-database — MIT, TypeScript + SRD JSON (the dnd5eapi dataset), active 2026-10.
- lorebench-tables — github.com/lorebench-tools/lorebench-tables — 876 entries (NPC/town/tavern names, shops, hooks, wilderness, magic/cursed items, rumors, dungeon rooms, factions, trinkets) as JSON + CSV + Markdown + Foundry RollTable JSON; free-use licence; 2026-06.
- datasworn / dataforged — github.com/rsek/datasworn (2024-11, no SPDX), github.com/rsek/dataforged (2023-12, NOASSERTION) — Ironsworn/Starforged oracle + asset data as npm/JSON.
- autorolltables — github.com/autorolltables/autorolltables.github.io — 131★, 2026-08, large table collection but embedded in app JS and NOASSERTION licence (extraction + terms check needed).
- d123d/awesome-dnd — github.com/d123d/awesome-dnd — index of SRDs/datasets/asset bundles, useful sourcing map.
- The `perhaps` markdown-table format (github.com/script-wizards/perhaps) is the closest thing found to a portable, spec'd table interchange format.

Note: the awesome-tabletop-rpgs / awesome-ttrpg lists tried by raw.githubusercontent URL were 404; fetched awesome lists mostly cover web apps, not CLIs.
