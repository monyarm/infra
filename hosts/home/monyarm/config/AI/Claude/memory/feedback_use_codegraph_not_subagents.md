______________________________________________________________________

## name: use-codegraph-not-subagents description: Use codegraph_explore directly for file/symbol lookups in this repo instead of spawning Explore/general-purpose subagents. metadata: node_type: memory type: feedback originSessionId: 74c5db7b-ab51-4980-8efe-cbc176d05847

Don't spawn subagents (Explore, general-purpose) to look up files, symbols, or "how does X work" in this repo. Use `mcp__plugin_hm_codegraph__codegraph_explore` directly — it's already indexed and returns verbatim source + call graph in one call.

**Why:** User flagged that subagent dispatch for lookups this repo's codegraph MCP server already serves is wasted overhead — cold-start re-derivation of context that codegraph answers in one sub-millisecond query.

**How to apply:** Before reaching for the Agent tool with Explore/general-purpose for "where is X", "what calls Y", "how does Z work", or before editing a symbol, call `codegraph_explore` first. Only fall back to subagents/grep for things codegraph can't answer (e.g. non-code file content, external docs, or genuinely open-ended multi-location research it doesn't cover).

If a workflow (e.g. plan mode's phase 1) mandates dispatching an Explore subagent regardless, tell that subagent in its prompt to use `codegraph_explore` as its primary lookup tool instead of a grep/Read loop — same rationale, applied one level down. Confirmed 2026-08-19: user explicitly asked for this "best of both worlds" instead of picking one over the other.
