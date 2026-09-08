---
name: feedback-listtoattrs-first-wins
description: "builtins.listToAttrs keeps the FIRST occurrence on duplicate names, not the last"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5ac9d091-64cb-4c8b-bf5a-bdba0522e8d0
---

`builtins.listToAttrs` keeps the **first** matching `name` when a list has
duplicate names, not the last. Building a lookup table via `listToAttrs
(map (e: nameValuePair e.someKey e) (attrValues someAttrset))` when
`someAttrset` can contain stale/orphaned entries sharing the same
`someKey` as newer ones is a real footgun: whichever entry sorts first
alphabetically among the attrset's keys silently wins, regardless of which
one is semantically "current."

**Why:** hit this directly — a Minecraft/PrismLauncher module's
`componentsByUid` table was built this way over `sources.nix` entries.
Orphaned single-version entries left over from early testing (`mc1201`,
`forge47_4_0`, ...) shared a `uid` field with the new all-versions entries
(`minecraft`, `forge`, ...) and sorted first alphabetically (`f`/`m` <
`fo`/`mi` in the relevant comparisons), so `getComponent` kept resolving
to the old, wrong-shaped data no matter how the new data was fixed. Took
several rounds of "why does this still fail" before tracing it to
`listToAttrs`'s actual precedence rule.

**How to apply:** when deduping by a derived key in Nix, either (a)
filter the source attrset to only the intended-format/current entries
before building the list (what fixed it here — `e ? versions` distinguished
new-format from old), or (b) reverse the list before `listToAttrs` if
"last wins" is actually wanted, or (c) just don't create stale duplicate-key
entries in generated data in the first place — clean up orphaned entries
promptly rather than letting them accumulate as a live footgun.
