---
name: feedback_flake_lock_root_nixpkgs_node
description: "flake.lock's root nixpkgs is .nodes.root.inputs.nixpkgs (e.g. nixpkgs_5), not .nodes.nixpkgs"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 28b4d7e1-1427-49cd-bda8-2e85c0e57265
  modified: 2026-11-05T07:26:52.355Z
---

To read the pinned nixpkgs rev, resolve `.nodes.root.inputs.nixpkgs` first (e.g. `nixpkgs_5`), then read `.nodes[<that>].locked`. `.nodes.nixpkgs` belongs to some transitive input (here it's determinate-nix's), and it can be weeks older.

**Why:** I once told the user their lock was 10 days stale by reading `.nodes.nixpkgs`. In fact it matched the channel head, and the user had to correct me.

**How to apply:** For any "which nixpkgs are we on" question, run `jq -r '.nodes[.nodes.root.inputs.nixpkgs].locked' flake.lock`. The same applies to any other input name.
