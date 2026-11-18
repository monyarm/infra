---
name: feedback-nixpkgs-lag-use-sources-fetchgittree
description: "User preference: when pinned nixpkgs lags upstream or lacks the engine, vendor it via sources.*.toml + fetchGitTree and override the nixpkgs src, not wait or accept the old version"
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T23:22:15.410Z
---

For every engine/reimplementation in a plan, check the pinned nixpkgs version against upstream; if nixpkgs lags behind or lacks the package, the user prefers handling it ourselves through `sources.*.toml` + the repo's `fetchGitTree`, overriding the nixpkgs `src`/version (e.g. `pkgs.theforceengine.overrideAttrs (_: { version = sources.tools.x.date; src = fetchGitTree sources.tools.x; })`) rather than using the stale package or waiting for it to land.

**Why:** stated directly by the user on 2026-11-17 ("if nixpkgs lags behind, i'd prefer to handle it using our sources.*.toml and fetchGitTree, and overriding the nixpkgs src"); the same policy was set 2026-11-14 for the boomer-shooter engines. It keeps behaviour consistent across packages and avoids pinning staleness.
**How to apply:** report nixpkgs vs upstream for each candidate before writing the plan, then mark each as "reuse nixpkgs" (versions match) or "own source override / new derivation". When an upstream needs submodules or similar build features (OpenJKDF2), extend the generic fetcher with an option (e.g. `submodules ? false`) instead of bypassing sources.toml.
