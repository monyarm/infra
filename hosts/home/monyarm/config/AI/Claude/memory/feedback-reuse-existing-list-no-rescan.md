---
name: feedback-reuse-existing-list-no-rescan
description: If the owned-games list (or any inventory) is already produced/available, cross-reference it directly — never re-derive it with a filesystem find/scan.
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T17:33:06.844Z
---

When an inventory has already been produced or is sitting in the repo (owned games in `games.list`, a scan tool's output, earlier results in the session), use it directly — do not launch `find`/`grep`/filesystem scans to re-derive it.

**Why:** the user reacted with "THE FUCK! YOU ALREADY GOT THE GAME LIST, WHY ARE YOU DOING A FIND THAT WILL TAKE YEARS" (2026-11-16) when a broad `find` was started even though the owned-game list was already in hand; re-deriving known data burns minutes and looks careless. Same family of complaint as [[no-du-whole-nix-store]].

**How to apply:** before any wide search, ask what already answers the question — read `games.list`, `~/.local/share/game-library-scan/already-defined.json`, existing comments in the relevant module, or the list the user just pasted — and cross-reference locally. Only search when the needed fact genuinely isn't recorded anywhere.
