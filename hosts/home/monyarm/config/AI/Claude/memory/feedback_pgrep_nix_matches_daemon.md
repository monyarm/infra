---
name: feedback-pgrep-nix-matches-daemon
description: "`pgrep -x nix` false-positives on nix-daemon processes; match eval command lines instead"
metadata:
  node_type: memory
  type: feedback
  originSessionId: cb0eef67-507e-4138-83ba-ee5f2a9a8f57
  modified: 2026-11-05T07:54:29.159Z
---

`pgrep -x nix` (the AGENTS.md pre-eval check) hits nix-daemon and similar background processes, so it isn't a reliable "another eval running" signal.

**Why:** the user reported it firing on nix-daemon.
**How to apply:** check with `pgrep -af '^nix (build|eval|flake|develop|fmt)|nix-instantiate'` and read the printed command lines before deciding an eval is competing.
