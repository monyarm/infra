---
name: steam-auth-direnv
description: Real Steam auth for fetchSteam/DepotDownloader builds comes from direnv (.envrc decrypts sops secrets into .env)
metadata:
  node_type: memory
  type: reference
  originSessionId: d9849497-7077-4474-81c7-0efaaa9cdf6c
  modified: 2026-11-07T00:11:20.001Z
---

For builds needing real Steam login (fetchSteam on owned depots), run `direnv allow` in ~/.nix, then wrap commands as `direnv exec . <cmd>` (or source `.envrc`/`.env`). `.envrc` decrypts sops secrets to `.env`, copies to `/tmp/.env`, and adds sandbox paths `/secrets` + `/steam-session` (persisted DepotDownloader login, avoids 2FA each build).

Anonymous `steamcmd-minimal +login anonymous +app_info_print <appid>` works for depot/manifest gid discovery without auth.
