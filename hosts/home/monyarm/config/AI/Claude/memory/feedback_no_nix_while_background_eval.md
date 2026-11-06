---
name: feedback-no-nix-while-background-eval
description: Never run any nix eval/build (incl. small getFlake --expr lookups) while a background nix flake check/build/eval is running
metadata:
  node_type: memory
  type: feedback
  originSessionId: cb0eef67-507e-4138-83ba-ee5f2a9a8f57
  modified: 2026-11-05T08:15:58.230Z
---

While a background `nix flake check`/`nix build`/`nix eval` runs, run no other nix command at all, including "small" `nix eval --expr '(builtins.getFlake ...).inputs.X.outPath'` lookups. Each getFlake re-evaluates the flake.

**Why:** on 2026-11-05 I started `nix flake check --impure` in the background, then ran two getFlake input-path evals alongside it. RAM ran out, the session crashed, and the user's PC nearly went down.
**How to apply:** resolve input store paths (stylix, home-manager, ...) *before* starting the long background eval, or wait for its completion notification. Do only non-nix work (reading files, editing) while it runs. Related: [[feedback-pgrep-nix-matches-daemon]].
