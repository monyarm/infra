---
name: feedback-no-full-toplevel-build-for-verification
description: Never run the full nixosConfiguration toplevel build just to verify game/package changes; build only the specific outputs — user killed such a build mid-run
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T15:04:24.645Z
---

Do not run `nix build .#nixosConfigurations.gaming-laptop.config.system.build.toplevel` (or any full system toplevel) merely to verify game/package changes. Build only the specific outputs touched (e.g. `programs.steam.games.<K>.game`, `packages.x86_64-linux.<pkg>`, `games.<x>.engine`, `checks.x86_64-linux.treefmt`).

**Why:** On 2026-11-16, after the per-game Steam/engine outputs had all built, a toplevel build was started as "the only thing never built this session". The user interrupted with "no, dont run the full toplevel" and then "STOP THE FUCKING TOPLEVEL BUILD"; the process was killed by SIGTERM. The session then committed without it.

**How to apply:** When the user says "test the builds", interpret it as the changed derivations, not the whole system. Do not start a toplevel build on your own initiative as a final confidence check — if a full-system build seems needed, ask first. Related: [[feedback-dont-build-wadfusion-merge]], [[feedback_no_unasked_activation]].
