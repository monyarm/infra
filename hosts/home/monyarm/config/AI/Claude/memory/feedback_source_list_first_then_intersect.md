---
name: source-list-first-then-intersect
description: "When cross-referencing an owned-games/library list against an external category (engine reimplementations, DOSBox-compatible, ScummVM, a compat-tool's game list, etc), pull the authoritative external list first, then intersect -- don't grep the local list for titles recalled from memory and verify one by one."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b656f3b3-9490-4f58-8d3b-503c30089fc5
---

Get the full external list (via WebSearch/PCGamingWiki/a tool's own game list, e.g. a compat layer's supported-games page) first, THEN compare that list against the local data (e.g. `games.list`). Do not start from memory-recalled candidate titles and grep the local list to confirm them -- that direction misses anything not already remembered and wastes verification effort per-title instead of once per source list.

**Why:** Caught during a games.list survey task -- asked to find Linux/engine-reimplementation/DOSBox/emulated candidates. My first-draft plan proposed grepping `games.list` for titles I recalled (X-COM, Baldur's Gate, etc.) and verifying each individually. User corrected: get the whole external list first (e.g. all known engine-reimplementation projects and what they cover, PCGamingWiki's DOSBox-compatible games list), then compare that against `games.list`.

**How to apply:** Any "which of my owned/local items match category X" task where X has an authoritative or well-documented external list. Source-list-first also surfaces items memory would never have recalled. See [[feedback_delegate_noisy_research_to_subagents]] for how to fetch these source lists without polluting main context.
