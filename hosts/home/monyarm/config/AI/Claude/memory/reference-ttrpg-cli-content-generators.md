---
name: reference-ttrpg-cli-content-generators
description: Survey (2026-11-16) of terminal CLI tools that generate TTRPG content (tables, loot, taverns, names, dungeons, NPCs) — the peer class of GemMakerDnD / Book-Keeper
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T21:17:37.106Z
---

Survey 2026-11-16 of CLI (non-GUI) TTRPG content generators, as peers of the user's own monyarm/GemMakerDnD (random gems w/ value filtering) and monyarm/Book-Keeper (random book titles, JSON data). Niche is thin.

Strongest, verified:
- twas — github.com/DrPlantabyte/twas — table-driven text substitution (`${animal}`), recursive/weighted; Rust `cargo install twas --features=app`; MPL-2.0; 2026-02-27; no bundled data (txt/csv/json/yaml tables you supply).
- TALE — github.com/kaedr/tale — DSL for random-table books + REPL/CLI (`tale tables.tale`); Rust; MPL-2.0; v0.1.0 2026-01-04; prebuilt binaries.
- perhaps — github.com/script-wizards/perhaps — markdown random tables, Perchance-style subset, seedable, spec'd; TypeScript npm/npx `@scriptwizards/perhaps`; Apache-2.0; 2026-11-10; successor to archived script-wizards/oracle. Only TS entry.
- dnd-encounter — github.com/zachreborn/dnd_encounter_generator — offline 5e (SRD 5.2.1) encounter generator with party-size/level/difficulty/type filters + `--seed`/`--catalog`; Python ≥3.12, no deps; bundled JSON (330 stat blocks); 2026-11-10. Closest to GemMaker's filtering style.
- loot-cli — github.com/Tortured-Metaphor/loot — random loot w/ rarity+prices; Rust MIT; 2026-04-14; cargo.
- tavern-cli — github.com/Tortured-Metaphor/tavern — tavern names/menu/drinks/barkeep/rumors; Rust MIT; 2026-04-14.
- rpgmap — github.com/seilis/rpg-tools — ASCII grid dungeon/cave generator; Rust GPL-3.0; v1.4.0 2026-07-18 (v1.4 also ships a GUI; CLI primary).
- nameforge — github.com/DoNotResuscitate/nameforge — markov name gen, TUI + CLI; Go GPL-3.0; 2026-10-07; release binaries w/ bundled data.
- rng / random_name_generator_rs — github.com/folkengine/random_name_generator_rs — Rust BSD-3; ~84k downloads.
- traveller-npc-generator — github.com/carloscasalar/traveller-npc-generator — Go MIT; `make build` → out/generate-npc; bundled YAML.
- Henchgen-II — github.com/Golan2072/Henchgen-II — ACKS II henchman gen; Python GPL-3.0; bundled data; bare script.
- opendnd — github.com/opendnd/opendnd — `dnd name|person|domain|dynasty`; Node MIT; npm opendnd@0.5.3 frozen since 2020-03.
- RustHexCrawlGenerator — github.com/L-Mann/RustHexCrawlGenerator — markdown hex key CLI; Rust GPL-3.0; 2025-02-23; hobby-grade.
- dungeon_generator — github.com/whitemage12380/dungeon_generator — Ruby 5e DMG dungeon gen; no license; 2022-11-11.
- DndBusGenerator — github.com/jamesjohannesson/DndBusGenerator — village→city business sets; Python CC0; 2026-04-02.
- dmn — crates.io/crates/dmn — AD&D DM CLI+lib; AGPL; 2023-10; declared repo git.aikuro.net no longer resolves, crates.io source only.

Excluded as not-CLI: donjon.bin.sh, Eigengrau's EEG (private, no bin), Watabou/Procgen Arcana, Azgaar, 5e.tools, Perchance, Chaotic Shiny (web); wintermute-cell/faction-generator (Go templ web server); sectors-without-number (Electron); BnB-LootGenerator (PyQt); DnDGen (C# libs); auto-stuff-generator + JHStoops/ttrpg-tools (libs, no bin).

Known gaps as of 2026-11-16: no maintained CLI for weather generation, pointcrawl generation, or a DMG-style 5e treasure-hoard roller with bundled DMG tables.
