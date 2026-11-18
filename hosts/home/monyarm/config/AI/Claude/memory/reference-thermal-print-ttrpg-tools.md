---
name: reference-thermal-print-ttrpg-tools
description: "Survey (2026-11-16) of snd-like thermal-printing tools: snd-no-ai fork, Mo / momir-basic-printer for MTG, ESC/POS libraries; no other general TTRPG peer exists"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T21:04:58.210Z
---

Surveyed 2026-11-16 for thermal-printing TTRPG tools comparable to Sales & Dungeons (snd); conclusion: snd has no real TTRPG peer.

- OrionW06/snd-no-ai — fork of snd with the AI/LLM surface removed ("Now without AI Slop!"), MIT, created 2026-04-16, same tree layout (cmd/, frontend/, printing/, thermalprinter/epson/, rpc/, server/). Drop-in replacement for our snd packaging if an AI-free build is wanted (costs one sources entry + a second package).
- ojazeker/Mo — Flask app on a Pi for MTG Momir Basic, offline Scryfall data, dithered card/token printing (not TTRPG).
- MoritzHayden/momir-basic-printer — Python, prints a random MTG card by CMC, Pi or ESP32, ships a systemd unit (not TTRPG).
- Libraries (not apps): Klemen1337/node-thermal-printer (Node ESC/POS driver), FilipChalupa/virtual-thermal-printer (fake ESC/POS printer in a browser — useful for testing templates without paper).
- Paper/PDF handout generators, not thermal: Cthulhu Architect's handout generator, Felipe Lippelt's immersive-terminal handout set.
- Everything else printing to 58 mm is POS/receipt software.

Caveat: itch.io/GitHub topic pages were not exhaustively checked, so a fresh project could exist under a non-obvious name.
