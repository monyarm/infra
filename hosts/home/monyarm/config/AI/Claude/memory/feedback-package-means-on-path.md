---
name: feedback-package-means-on-path
description: When packaging a tool/binaries the user asked for, also wire it into a profile (home.packages) so the command is runnable — the user got angry about built-but-unreachable tools
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T20:17:09.136Z
---

"Package X into the repo" means X must end up on the user's PATH, not just build in the store. When snd / snd-workshop were packaged but never added to any module, the user's reaction was "WHAT! YOU DIDNT PUT THEM IN THE PATH!? HOW AM I MEANT TO START THEM".

**Why:** a derivation that only exists in `packages/` is unusable for the user; the goal was running the tool, not producing a store path.

**How to apply:** as part of packaging a new tool the user intends to launch, add it to a package module in the same change — user tools go in `hosts/modules/packages/apps.nix` (home-manager module → `home.packages`), not `environment.systemPackages`, unless it is a system service or needed by other users. Then eval-check that the command appears in `homeConfigurations.monyarm.config.home.packages` and say explicitly that a deploy is needed to reach PATH.
