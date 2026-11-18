---
name: reference-dos-games-with-foss-engines
description: "2026-11-17 survey: which of the owned DOS titles have a FOSS engine/reimplementation (OpenTyrian, KeeperFX, dethrace, ReflectionHLE, Wargus, War1gus, OpenTESArena, R.E.L.I.V.E.), the DOSBox-or-nothing remainder, and the Keen-pack / Windows-build edge cases"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T23:27:58.270Z
---

Survey answered 2026-11-17 over the owned DOS titles ("31 DOS titles" is the loose framing), looking for engine alternatives before falling back to `buildDosBox`.

**Has a FOSS engine (9):**
- Tyrian 2000 → **OpenTyrian** (in nixpkgs, current)
- Dungeon Keeper Gold → **KeeperFX** (new package needed; DK1 only)
- Carmageddon Max Pack → **dethrace** (no nixpkgs; upstream active but still work-in-progress)
- Bio Menace → **ReflectionHLE** (`BMenace`; no nixpkgs; also official freeware)
- Keen Dreams → **ReflectionHLE** (`KDreams`; same derivation/upstream project as Bio Menace)
- Warcraft II BNE → **Wargus** (nixpkgs, current)
- Warcraft: Orcs & Humans → **War1gus** (new package)
- The Elder Scrolls: Arena → **OpenTESArena** (no nixpkgs; upstream active but still missing saves, quests and spells)
- Oddworld: Abe's Oddysee → **R.E.L.I.V.E.** (no plan yet; only in the engine-candidates CSV)

**No engine — DOSBox or nothing:** the SSI Gold Box set (Forgotten Realms Archives 1–3, Ravenloft, Dark Sun, Krynn, Al-Qadim, Stronghold, Silver Box Classics), DragonStrike, Fantasy Empires, Spelljammer, Realms of the Haunting, the two Call of Cthulhu adventures (Shadow of the Comet, Prisoner of Ice — ScummVM does not handle them), Time Commando, Stargunner, Jill of the Jungle, Biing!. "Gold Box Companion" is a helper overlay, not a runtime. Master of Magic Classic has only the incomplete Java clone MoM IME, which does not consume the original data.

**Edge cases / corrections:**
- **Commander Keen Complete Pack** is the awkward one: ReflectionHLE covers *Keen Dreams* only; Keen 1–6 are the Galaxy/Vorticon engines and are in no port, so the pack stays on DOSBox.
- Warcraft II B.net Edition and Oddworld: Abe's Exoddus are **Windows** builds in the GOG release (they would run under Wine); Wargus makes the Warcraft II data irrelevant anyway.

**How to apply:** when a DOS title comes up, check this list before proposing a DOSBox profile — the marquee titles are better served by the engines above; the long tail (SSI Gold Box packs, Keen 1–6, Time Commando) stays on DOSBox. Do not claim an engine is a drop-in replacement when upstream is still incomplete (dethrace, OpenTESArena).
