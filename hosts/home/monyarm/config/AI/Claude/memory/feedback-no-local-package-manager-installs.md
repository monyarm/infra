---
name: feedback-no-local-package-manager-installs
description: Do not run package-manager installs (npm install, pnpm install, etc.) on this machine, even as a "fast reproduction loop" — resolve npm dep issues inside the derivation or via sources.*.[npm]
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T18:35:09.312Z
---

Never run `npm install`/`pnpm install`-style package-manager installs locally on this machine, including as a quick reproduction loop while debugging a Nix build.

**Why:** The user reacted strongly ("WHY ARE YOU RUNNING NPM INSTALL LOCALLY!?"); local installs are unwanted side effects (node_modules, lockfile churn, unpinned registry fetches) on a machine whose packages are supposed to come from the Nix/sources pipeline.

**How to apply:** Reproduce and fix npm dep problems inside the derivation build (`nix build`, read the build log) or through `update-sources.py`'s `[npm]` handling in `sources*.toml`; if a dependency genuinely cannot build under the npm hook, report the blocker and propose options rather than hacking it locally.
