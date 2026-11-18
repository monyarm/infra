---
name: feedback-handling-means-mods-and-pcgw-tweaks
description: When judging which owned Linux-native titles merit work in the repo, the criterion is mod support and PCGW performance/gameplay fixes, not merely whether the game runs natively
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-17T01:21:52.535Z
---

When asked which of the user's owned games warrant "handling" in the repo, do not reduce the answer to "it already has a native Linux build, so nothing to do".

On 2026-11-17, after two misses on this question, the user spelled the criterion out: "Mod support, various tweaks according to pcgw for better performance or gameplay, those are all things that would warrant consideration for handling."

**Why:** the user's interest is in making owned games better to play — mod loaders, bundled-runtime repair, and PCGW-documented launch-option fixes all count as work worth doing even when the port runs fine. A "runs natively → done" verdict reads as not answering the question.

**How to apply:** evaluate each owned title on three axes — native/Linux status, whether a real mod ecosystem exists (loader + how mods install), and PCGW-documented fixes (vsync/offscreen renderer/`-novid`-class launch args). One-line launch-option fixes belong in `programs.steam.games.<KEY>.args`, not in a new module.
