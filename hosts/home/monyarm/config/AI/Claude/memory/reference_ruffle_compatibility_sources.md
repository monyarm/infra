---
name: ruffle-compatibility-sources
description: "How to determine whether a Flash game runs in Ruffle: ruffle.rs/compatibility VM stats, Newgrounds ?emulate=flash, Armor Games list, Flashpoint, Internet Archive, ruffle GitHub issues, 509-game test"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T19:23:37.723Z
---

How to check whether a Flash/SWF title actually runs under Ruffle (researched 2026-11-16).

## Fastest real check: Ruffle's own issue tracker
`https://api.github.com/repos/ruffle-rs/ruffle/issues?labels=air&state=all&per_page=100` (label `air`) plus `https://api.github.com/search/issues?q=repo:ruffle-rs/ruffle+"<game name>"` gives actual test reports from people who ran the game's SWF. Unauthenticated: 10 search req/min, 60 core req/hr — batch carefully.

AIR support state: `flash.filesystem.File` exists **desktop-only** (#14178, merged); `FileStream` (#19294), `NativeWindow` (#14984), `Screen` (#17608), `ServerSocket` (#24132), `DatagramSocket` (#14180) are all still missing. So any AIR game that writes saves to disk or creates its own window will not boot in Ruffle.

## Where to check compatibility generally
- **No official per-game database.** `https://ruffle.rs/compatibility` tracks only the VM: AVM1 (AS1/AS2, pre-Flash 9/2006) = language 99% / API 82%; AVM2 (AS3, post-2006) = 90% / 82%. Rule of thumb: pre-2006 content near-certain, AS3 "usually works, test it".
- **Newgrounds is the best live tester**: appending `?emulate=flash` to any `/portal/view/<id>` URL forces Ruffle; staff only flip Ruffle on by default for confirmed-compatible posts.
- **Armor Games** keeps a dated list at `armorgames.com/page/flash-games-playable-using-ruffle`.
- **Flashpoint Archive** ships Ruffle as a player engine with per-game results; **Internet Archive** Flash collections render through Ruffle in-browser (working archive entry = working Ruffle; dead-server dependencies like Mochi ads break games in any emulator).
- Empirical: `onlyfreeonlinegames.com/ruffle-compatibility/` — 509 casual 2009-2014 games on a late-2026 build, 99% started; "starts and draws" ≠ playable to the end (Flash Text Engine gaps bite later).

**How to apply:** before packaging a Flash title, check its ActionScript generation (PCGW engine field or SWF header) — AS1/AS2 safe, AS3 per-title test — then try the SWF in the desktop Ruffle. For the 13 owned Flash/AIR titles see project_owned_library_runtime_categories; only Samorost 1 is cleanly playable, the Jackbox titles, Brawlhalla and Evoland 2 are blocked on AIR filesystem APIs.
