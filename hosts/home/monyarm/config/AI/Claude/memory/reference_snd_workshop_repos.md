---
name: reference_snd_workshop_repos
description: Catalog of the 11 official Sales & Dungeons workshop repos (BigJk, nbadal, frshbeetz, Elfenspalter, michaelkleinhenz, Lavaill) with what each one contains, plus where the official list lives
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T19:09:21.459Z
---

Sales & Dungeons workshop content sources. The official list is the `snd-package-repo` README (Templates/Data sources/Generators from the community; publishing requires joining the S&D Discord https://discord.gg/5MUZEjc). Enumerated 2026-11-16 (11 repos):

- `BigJk/snd-default-templates` — official examples: `simple-message`, `dither-example`. 2024-02. Good sanity check of the print pipeline, nothing game-specific.
- `BigJk/snd-bigjk-templates` — the big general-purpose one: 5-6 templates/data (`bfrpg-monsters`, `map-text`, `monsters`, `mtg-token`, `ose-monsters`) + 11 generators (dice-roller, dungeon-generator, dungeon-card, fantasy-name-gen, universal-npc-emu, dm-emu-random-event, space-station-gen, dcc-level0-char, cwn-{corp,gang,npc}-generator, ose-quick-equipment). Covers 5e/OSE/DCC/CWN. 2024-09.
- `BigJk/snd-open5e` — 5e data sources only: magic items, monsters, spells, weapons; pairs with the `BigJk_monsters` card template. 2022-05.
- `BigJk/snd-srd-bestiary` — one 5e SRD bestiary data source; needs a card template to print. 2022-05.
- `BigJk/snd-bfrpg-monster` — one Basic Fantasy RPG SRD monster data source. 2022-05.
- `nbadal/snd-nbadal-templates` — three card templates (item, monster, spell); no data sources or generators. 2023-01.
- `frshbeetz/snd-EVT-templates` — largest single collection: ~21 OSE data sources split by topic (class abilities per class, equipment categories, monsters, spells, treasure types, swords/rings/potions/rods) plus `random-encounters` and `frshbeetz_encounters`; basically an OSE SRD dump. 2023-01.
- `Elfenspalter/SalesAndDonkeys` — generic sci-fi: 3 generators (spacestation, npc-generator, random-names); no templates/data. 2024-09.
- `Elfenspalter/SD_MoSh` — Mothership: 2 generators (character-generator-m, mosh-diceroller). 2024-09.
- `michaelkleinhenz/snd-fightclub5e-templates` — templates for the FightClub5e data source (item/monster/spell cards) + 2 LLM-backed generators (`aiadventurehook`, `aifantasyfluff`); the FightClub5e data source is not in the repo. 2025-03.
- `Lavaill/snd-tatourmi-templates` — the only one designed for thermal paper styling: 5 Mothership templates (contract, crew-ledger, mission, oxygen-bill, wound) with its own `mothershipThermal.css`/`render.js`/style guide. Newest (2026-04).

Repo entry kinds map 1:1 to S&D's file-based import RPCs (`importsTemplate*`, `importsSource*`, `importsGenerator*`), so each can be a pinned `[git]` source folder in `sources.ttrpg.toml` and seeded locally.
