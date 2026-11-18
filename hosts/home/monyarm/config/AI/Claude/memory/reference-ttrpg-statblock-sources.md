---
name: reference-ttrpg-statblock-sources
description: "Verified 2026-11-16 survey of quick stat-block sources by system: fiender CLI, Open5e v2 API, monstro.cc JSON (OSR), pf2ools-data, PathfinderMonsterDatabase, dnd-mcp; and which systems have no open dataset"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T21:39:24.949Z
---

Survey 2026-11-16 of quick ways to get monster/stat blocks, per system.

5e:
- fiender — Rust CLI, `cargo install fiender`; wraps open5e. `fiender -m kobold` prints a markdown stat block to stdout, `-s "eldritch blast"` for spells. Markdown output so `fiender -m goblin | tp` can print to the thermal printer. Limitation: exact name match, markdown-only output.
- Open5e v2 API — `curl -s 'https://api.open5e.com/v2/creatures/?name__icontains=goblin' | jq`. Covers 22 sources: SRD 5.1 and 5.2, Tome of Beasts 1–3, A5E Adventurer's Guide / Monstrous Menagerie, Black Flag, Deep Magic; 3,200+ monsters. Free, no key.
- 5etools-format JSON (bestiary-*.json, one file per book) for offline use; the format most tools ingest.

OSR:
- monstro.cc — 1,286 monsters / 1,601 stat blocks across BFRPG, OSE Classic + Advanced, OSRIC, Carcass Crawler. Per-page JSON: `curl monstro.cc/monster/blink-dog/index.json`, plus filtered indexes `/hitdice/4/`, `/type/undead/`, `/sourcebook/ose-classic-fantasy/`. Caveat: accuracy unverified.

PF2e:
- Pf2ools/pf2ools-data — MIT, JSON, one file per stat block plus bundles/ and indexes/; cleanest offline dataset, ~10 lines of jq over bundles/. No maintained CLI.
- Web: pathfinder2e.org/bestiary (filter by level/traits/source), monster.pf2.tools (edit/export JSON/PDF).

PF1e:
- c0d3rman/PathfinderMonsterDatabase — scrape-derived data.json of all aonprd monsters.

Agent-exposed options: dnd-mcp (Node, open5e v2, includes encounter building), mnehmos.open5e.mcp, srd-5.2.1 (322 monsters + conditions, stdio MCP + hosted endpoint).

Not available: Call of Cthulhu, Blades in the Dark and most non-OGL systems — stat blocks not openly licensed, no dataset exists.

Suggested minimal setup (offered, not yet implemented as of 2026-11-16): package fiender and add a small `statblock` wrapper over open5e + monstro JSON for fuzzy search and OSR in one command.
