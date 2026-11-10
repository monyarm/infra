---
name: run-locally-by-default
description: Run builds/scripts on this machine unless the user explicitly names a remote host for that run
metadata:
  node_type: memory
  type: feedback
  originSessionId: d9849497-7077-4474-81c7-0efaaa9cdf6c
  modified: 2026-11-10T10:51:39.474Z
---

Run nix builds and repo scripts (measure-compression etc.) locally by default. Never ssh to the desktop (monyarm@monyarm) to run them unless the user explicitly says to for that task.

**Why:** I ran measure-compression over ssh on the desktop because the CSV diff lived there; user had not asked, and the remote lacked Steam auth so it failed with Steam Guard prompts.

**How to apply:** reading remote state (git diff etc.) when asked is fine; executing builds there needs an explicit instruction. Related: [[steam-auth-direnv]].
