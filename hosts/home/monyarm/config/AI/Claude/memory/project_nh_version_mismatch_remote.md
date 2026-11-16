---
name: project_nh_version_mismatch_remote
description: "Resolved 2026-11-16: remote host showed nh 4.2 not because of stale activation but because an imperative `nix profile install nh` (nh-1 → 4.2.0) sits in the same buildEnv as home-manager-path on non-NixOS and wins the collision; fix is `nix profile remove nh-1`"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T16:47:35.033Z
---

Host `monyarm@monyarm` (non-NixOS, deployed via `stow.sh` → `nh home switch`) showed `nh` 4.2 while this device had the expected 4.5.0-beta3. Diagnosed and resolved on 2026-11-16.

**Root cause — not a config or stale-activation problem:**
- On the remote, `~/.nix-profile` → `~/.local/state/nix/profiles/profile` → a `buildEnv` (`nyq13az916…-profile`).
- That buildEnv contains BOTH home-manager's `home-manager-path` (`/nix/store/5hsvl64y8…-home-manager-path`, which does contain `nh-4.5.0-beta3-c063ba1`) AND an old imperative package `nh-1` from `github:NixOS/nixpkgs/ebc94f855…` → `nh-4.2.0`.
- Home Manager on non-NixOS installs its `home-manager-path` *into* `nix profile`, so any `nix profile install <same binary>` collides and the imperative entry wins the buildEnv collision.
- Fix: `nix profile remove nh-1` on the remote (unprivileged, no re-deploy needed); a later switch keeps it fixed as long as nothing re-installs `nh` imperatively.
- Note the local `nh` 4.5.0-beta3 also appears at `/run/current-system/sw/bin/nh` (from the flake input overlay, rev `c063ba1`); pinned nixpkgs' own nh is 4.4.2.

**Why:** The wrong first diagnosis ("stale activation from an older lock/checkout") was disproven by inspecting the actual profile symlinks and buildEnv contents; version mismatches on non-NixOS hosts should be checked against `nix profile` contents first.

**How to apply:** When an HM-provided binary on a non-NixOS host reports a stale version, inspect `~/.nix-profile` → profile buildEnv → entries, and check for an imperative `nix profile install` of the same package before suspecting the lock or activation. Same shadowing risk unverified for `devenv`, `innoextract`, `legendary-gl`, which were also present in that buildEnv.
