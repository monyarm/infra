---
name: reference_owned_native_xna_fna_targets
description: "2026-11-17 shortlist of owned titles worth \"handling\": most Linux-native Steam builds need nothing, while the Windows-only/runtime-replaceable ones are Sonic Mania (RSDKv5), One Finger Death Punch (XNA), Survivalist/Freebie/Swipecart/Overture (XNA/FNA), plus LÖVE and FNA/Monocle titles to verify per title"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-17T01:16:24.639Z
---

Answer given 2026-11-17 to "any linux-native titles I own that would be good targets for handling" — treat the table as **verify before planning**, not as fact; the XNA/FNA column is exactly where a native Linux build hides or is missing per title.

**Needs nothing (Steam already runs their native builds)** — Portal/Portal 2/HL2/TF2/CS:S/L4D2, Celeste, Hades, Dead Cells, Terraria, Stardew, Hollow Knight, Balatro, Mindustry. Wire these only if the user wants a shortcut with custom flags.

**Real work (Windows-only shipped build, runtime packageable):**
| Title | Runtime | Why a target |
|---|---|---|
| Sonic Mania [584400] | RSDKv5 decomp | no Linux build at all — `sonic-mania.md` plan exists |
| One Finger Death Punch [264200] | XNA | no native build |
| Survivalist [340050], Freebie [487220], Swipecart [295930], Overture [343100] | XNA/FNA | Windows-only |

**Maybe (verify per title):** Balatro [2379780], Intravenous [1486630] are LÖVE and already native — only worth it to handle mod dirs; Axiom Verge [332200], Dust [236090], Chasm [312200], TowerFall [251470] are FNA/Monocle and most ship native.

**How to apply:** before writing a plan for any row below "needs nothing", confirm the shipped depot actually lacks a Linux build (Steam manifest / depot listing) instead of assuming from the runtime.
