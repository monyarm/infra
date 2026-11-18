---
name: reference_five_title_survey_am2r_drl_srb2_solarus
description: "Verified 2026-11-17 verdicts on five user-named candidates: AM2R (launcher in nixpkgs, Linux release broken, DMCA'd data), Beyond Castle Wolfenstein (DOSBox only), DRL/DoomRL (free FPC source + free assets, needs Lazarus/FPC/fpcvalkyrie + Lua 5.1), SRB2 2.2.15 and Solarus 2.1.4 (data-plumbing cheap wins, both plans now written), plus which plans were pending"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-17T01:17:03.538Z
---

Surveyed 2026-11-17 after the user declined the previously offered next batch ("No to those") and named these five instead.

- **AM2R** — nixpkgs *does* ship `am2rlauncher` (2.3.0-unstable-2026-07-22), but upstream's README opens with "**Notice: The AM2RLauncher Linux release is broken.**" and "**No copyrighted files are shipped, you need to provide your own copy of AM2R_11!**"; the game was DMCA'd by Nintendo in 2016, so there is no fetchable data. A Nix module could only wrap the launcher around a user-supplied file path; the Flatpak is the supported route. Viable only if the user already has AM2R_11.
- **Beyond Castle Wolfenstein** (1984) — no reimplementation exists and it is not freeware; DOS/Apple II/C64 only, so it is a `buildDosBox` title for the DOS pass.
- **DRL / DoomRL** — the only fully-free, fully-native candidate of the five. `ChaosForge/doomrl` publishes FreePascal source and the full asset set (sound, soundhq, music, mp3 folders, `drl.wad`, `core.wad`) is a free download from drl.chaosforge.org. Toolchain: Lazarus + FPC + `ChaosForge/fpcvalkyrie` 0.10.0, and **Lua 5.1 is compulsory** (DLL name hardcoded, headers written against 5.1) — a real derivation, not a wrapper.
- **Sonic Robo Blast 2** — `srb2` 2.2.15 in nixpkgs and current; game and engine GPL; mods are plain WAD/Lua addons loaded from an addons dir, so `games.srb2.mods` as an attrset feeding `linkFarm` needs nothing built.
- **Zelda: Mystery of Solarus DX** — free game data (`solarus-games/zsdx`) on the free Solarus engine; `solarus` 2.1.4 already in nixpkgs. Same shape as SRB2 (data plumbing + a shortcut entry), with one open check: whether ZSDX wants exactly 2.1.x or a newer engine.

Outcome: the user then chose all four, so on 2026-11-17 `drl.md`, `srb2.md` and `solarus-zsdx.md` were written to `/home/monyarm/.opencode/plan/` (design details in the plan-designs project memory, "Eleventh" batch). The Cosmo's Cosmic Adventure plan was written the same session (see the plan-designs project memory).
