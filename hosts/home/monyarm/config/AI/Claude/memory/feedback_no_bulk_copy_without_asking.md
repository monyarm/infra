---
name: feedback-no-bulk-copy-without-asking
description: Never run bulk store transfers (nix copy of a whole closure/--derivation toplevel) while debugging; keep diagnostics minimal
metadata:
  node_type: memory
  type: feedback
  originSessionId: cb0eef67-507e-4138-83ba-ee5f2a9a8f57
  modified: 2026-11-06T10:11:54.168Z
---

While debugging remote-builder issues, never run `nix copy` (or anything similar) on a whole closure, e.g. `nix copy --derivation <toplevel.drv>`, without asking first. A single tiny test path is the limit.

**Why:** on 2026-11-06, while debugging a stuck "waiting for the upload lock" build, I tried to copy the whole toplevel drv closure to the builder as a test. The user was furious: that is a huge transfer, and it is not what they asked for.
**How to apply:** use minimal probes only (`nix store info`, a 1-file test copy). For anything heavier, or anything that needs root, give the user the command and let them run it. Related: [[feedback-no-nix-while-background-eval]].
