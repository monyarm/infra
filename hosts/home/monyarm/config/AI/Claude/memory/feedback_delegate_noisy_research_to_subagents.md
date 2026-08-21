---
name: delegate-noisy-research-to-subagents
description: "For WebSearch/WebFetch-heavy research producing a lot of raw/junk results (e.g. surveying many external sources for a curated list), dispatch subagents per source/category and have them return only the distilled list -- don't run the raw searches in the main thread."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b656f3b3-9490-4f58-8d3b-503c30089fc5
---

When a task needs many WebSearch/WebFetch calls across multiple sources (e.g. researching several engine-reimplementation projects, or scraping a compat tool's supported-games list) and the goal is a short curated output (a list of games + brief notes), delegate each source/category to a subagent instead of running the searches inline. Tell the agent explicitly to return only the clean list (titles, links, short quirks/notes) -- not raw search dumps.

**Why:** Caught during a games.list survey task. User: "would probably be smart to use subagents for this, cause you'll get a lot of junk data in your searches, and all we really want is a list of games per category, and maybe some extra info for a few about quirks or specifics."

**How to apply:** Applies to external/web research (many searches, noisy results, small distilled output needed). Does NOT apply to local codebase lookups -- for those, use codegraph_explore directly, see [[feedback_use_codegraph_not_subagents]]. Pair with [[feedback_source_list_first_then_intersect]] -- the subagent's job is usually "get the full external source list for category X."
