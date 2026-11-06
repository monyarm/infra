---
name: feedback-no-unasked-config-edits
description: "Give me a solution" to a runtime problem means a fix to run, not an edit to the repo config; propose config changes and wait
metadata:
  type: feedback
---

When the user is debugging a runtime problem (stuck build, hung ssh, etc.) and says "give me a solution", give the commands that fix the live state. Do not edit the repo config unless they ask for that.

**Why:** on 2026-11-06 a stale ssh ControlMaster hung remote builds. I edited `ControlPath` in hosts/modules/base/default.nix unasked. The user was furious: the config had worked before, and only the live master process was stuck. I had to revert.
**How to apply:** for runtime breakage, hand over the unblock commands. A config change that would prevent a repeat gets proposed in one line and waits for an explicit yes. Related: [[feedback-no-bulk-copy-without-asking]].
