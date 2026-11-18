---
name: reference-freeware-games-with-engines
description: "2026-11-17 survey of games released free that have a FOSS engine/reimplementation: OpenOMF (OMF 2097), OpenRA (C&C/RA freeware), Aleph One, UQM, Abuse, Hugo/ScummVM, plus the free-data-but-no-Linux-engine and not-viable cases"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-17T00:33:33.237Z
---

Survey answered 2026-11-17 on "games that went free + have a Linux engine/decomp/recomp", excluding Unreal Tournament and titles the repo already covers (Daggerfall, Arena, Tyrian, Bio Menace, Wolf3D, DOOM, ScummVM freeware).

**Worth doing (free data + free engine + native Linux):**
- **One Must Fall: 2097 → OpenOMF** (MIT, ground-up C reimplementation, reads the original data): declared freeware by the developers on 1999-02-10 and the full registered version is the official download; ~7 MB data, OpenGL, rollback netcode instead of IPX, tournament mode, mod support; self-declared alpha but major gameplay present. Not in nixpkgs. Ranked the best fit of the set: one derivation + wrapper.
- **C&C: Tiberian Dawn + Red Alert → OpenRA** (GPL-3, C#): EA released both as freeware (~2008) and GPLv3'd the source in 2025; OpenRA's installer can fetch the freeware assets, so two complete RTS campaigns for free. `openra` is already in nixpkgs, so this is data plumbing, not an engine job. Caveats: EA states OpenRA is unendorsed, and Dune 2000 assets are not free.
- **Marathon 1 / 2 / ∞ → Aleph One** (`alephone` in nixpkgs): Bungie made the trilogy free with an open engine; zero work beyond fetching the free data.
- **Star Control II / The Ur-Quan Masters → UQM** (`uqm` in nixpkgs): fully free data and engine, no grey area.
- **Cosmo's Cosmic Adventure → Commander Genius** (Apogee freeware): already on the CG plan; one extra data fetch, no engine work.
- **Abuse**: Crack dot Com released game and source free; official SDL port is genuinely native and small.
- **Hugo trilogy (House of Horrors / Whodunnit / Jungle of Doom)**: all three released freeware by the author; ScummVM's Hugo engine handles them, so it is a data-only add-on to the existing ScummVM module — three titles for one entry.

**Free data, no Linux engine (Wine only):** Starsiege: Tribes / Tribes 2 / Earthsiege 1–2 — Sierra made Tribes 1+2 freeware in 2004, Hi-Rez re-released the whole back catalogue free in 2015, TribesNEXT still hosts installer + patch, but there is only a community *service*, no open engine/reimplementation, so it would be a Wine wrapper. Ken's Labyrinth builds natively (source + data released) but is a curiosity. Chex Quest is free and GZDoom already eats it.

**Free data, engine exists but not viable:** Jazz Jackrabbit 1 → OpenJazz (GPL, native) but only the shareware episode / Holiday Hare is legally free. Dune II → OpenDune has no official freeware release (abandonware-grade data). FreeSpace 2 → FSO has a free Linux engine but non-free data (needs the GOG copy). GTA 1/2 are free but openGTA and peers are abandoned/incomplete. Betrayal at Krondor has been free since 1997 and xBaK exists, but it is far from playable.

**Recommendation given:** queue **OpenOMF** next (only entry that is legally free data, a real native Linux engine, absent from nixpkgs, and small enough for one derivation); OpenRA is the bigger content prize but `openra` already exists so it is a data-plumbing job. Plans for OpenOMF and/or OpenRA were offered — no answer yet as of 2026-11-17.
