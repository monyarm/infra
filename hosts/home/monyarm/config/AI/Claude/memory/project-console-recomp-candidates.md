---
name: project-console-recomp-candidates
description: 2026-11-17 cross-reference of the user's ~236-row physical-collection CSV against RecompLauncher, with the user's later corrections (BBLIT/HP2/Flame dropped), the answer that the repo can already rip discs into the nix store, and the Wii-encryption blocker
metadata:
  type: project
  origin: opencode
  modified: 2026-11-17T00:17:34.992Z
---

2026-11-17 cross-reference of the user's **physical console collection** (a ~236-row CSV in `~/Downloads`, platform spread: PS2 61, PSP 57, PC 40, Wii 17, PS4 12, PS3 10, PS1 10, GBA 8, NDS 5, Switch/PS5/Starlink/N-Gage handfuls) against the RecompLauncher catalog.

**Genuine owned-platform matches:** Wii **Twilight Princess** → **Dusklight** 2.0.3 (best candidate); PS2 **Zone of the Enders** → ZOE-Recompiled 1.1.0; PS2 **Burnout Dominator** → Burnout Dominator Reversed 1.5.2; PS2 **GTA: Vice City Stories** → VCS Recompiled 0.1.11 (possible); PC 007: NightFire → Nightfire XBE Recomp 1.2.0 / Nightfire Rust. Weaker: OpenKai2, MediEvil PC 1.4.0, 3 unofficial PS4 Uncharted Collection ports.

**Corrected/dropped on 2026-11-17 after the user pushed back (verdicts stand, do not re-propose):**
- **BBLIT-Remaster** — Windows-only. Dropped.
- **HP2-Recompiled** — `Barthes-Recompiled/HP2-Recompiled` is the **Xbox** Chamber of Secrets, not the GBA one the user owns. Dropped.
- **Flame** (Dungeon Keeper 2) — Windows-only in practice: it patches the Windows DK2 binary/disk-Steam-GOG payload rather than reimplementing it, so nothing packageable. "DK2 has no engine" was wrong, but the practical answer (Wine/Proton) is unchanged.
- **NeoTS2** — NEO Scavenger [248860], not The Sims 2.
- **Serious Sam Classic** — dropped; the user is working on their own fork.
- **OpenJazz** — exists but the user owns no Jazz Jackrabbit (only Jazzpunk), so no plan.
- McRae05-XBE-Recomp (beta, xbox origin) and God of War II (ps3 recomp, macOS-only) rejected earlier.

**Disc-image question — user answered 2026-11-17:** they already have disc ripping set up so rips can land in the nix store (`lib/fetchers/disc.nix`, a redumper/CD-DVD SCSI pipeline needing `CAP_SYS_RAWIO`, `__noChroot`+`doas`). The residual unknown is **Wii discs, which are encrypted** and need an old raw-capable drive or a modded Wii. So the open design question narrowed from "do we need a `games.<x>.discImage` user-supplied-path convention" to "does the rip pipeline handle encrypted Wii media" — Dusklight's plan tests redumper first and keeps `games.dusklight.discImage` as the fallback.

**Why:** the match table is the result of filtering three large sources; redoing it is expensive and the platform-vs-origin distinction is easy to get wrong.
**How to apply:** reuse these verdicts instead of re-matching; treat the listed dropped titles as settled no's; for remaining console recompiles assume the existing rip pipeline supplies the image unless the disc is encrypted (Wii).
