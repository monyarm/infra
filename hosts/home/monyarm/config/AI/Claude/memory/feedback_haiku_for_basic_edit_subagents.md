---
name: feedback-haiku-for-basic-edit-subagents
description: "Use Haiku (not Sonnet) as the model for tightly-scoped, fully-inlined mechanical edit subagents."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2ef1c75b-4c96-4ac4-8f96-00e3ebef5713
---

When dispatching Agent tool calls for basic, fully-specified mechanical edits (e.g. "add this exact `images.icon = pkgs.fetchurl {...}` block to these N named entries across M files", with every url/sha256/target already resolved in the prompt), pass `model: "haiku"`.

**Why:** These tasks require zero judgment beyond locating the right block and doing an Edit call — the kind of subagent work established in [[feedback_use_codegraph_not_subagents]]-adjacent SteamGridDB-apply workflows. User explicitly asked for Haiku on these after a batch of apply-JSON subagents ran on the default model.

**How to apply:** Any time a subagent prompt consists mainly of "here is the exact before/after text, make N Edit calls, don't touch anything else" (the SteamGridDB apply-JSON pattern, straightforward multi-file mechanical renames, etc.), launch it with `model: "haiku"`. Reserve Sonnet/Opus for subagents that need to research, infer structure, or make judgment calls (e.g. figuring out *which* file/key a pick belongs to when it isn't already resolved).
