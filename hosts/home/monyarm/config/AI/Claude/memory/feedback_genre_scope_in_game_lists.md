---
name: feedback_genre_scope_in_game_lists
description: When the user asks for games of a named genre, keep the list to that genre — Carmageddon got swept into a boomer-shooter survey and was called out
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-13T23:18:35.597Z
---

A survey requested for a named genre (e.g. "boomer shooters") must contain only that genre. On 2026-11-14 the user asked "Why is Carmageddon listed when I asked for boomer shooters?" — a car-combat racer that had been swept in because the search was really for "owned + FOSS engine in nixpkgs" and the whole bucket was mislabelled.

**Why:** the user treats the genre label as a hard filter; extra titles that happen to share a technical property (having a FOSS engine in nixpkgs) make the list wrong and untrustworthy.

**How to apply:** when building a genre list, derive membership from the genre first (how a title plays), then intersect with the technical criterion — not the reverse. If something interesting is out of genre, mention it separately as such or leave it for its own survey, and say so once the mistake is noticed.
