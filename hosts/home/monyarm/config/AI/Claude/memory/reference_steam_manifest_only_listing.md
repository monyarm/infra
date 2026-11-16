---
name: reference_steam_manifest_only_listing
description: Use `direnv exec` + DepotDownloader/steamcmd `-manifest-only` to inspect a Steam app/depot file list without downloading content
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-13T17:48:00.914Z
---

To inspect a Steam app's depot file list without downloading content, run `direnv exec . depotdownloader -app <appId> -manifest-only` (or `steamcmd-minimal`) from the repo root; direnv supplies the sops Steam credentials and shared-secret TOTP, and the tool reports each depot's newest manifest ID/date. The manifests land under `.DepotDownloader/` and a readable `manifest_<depotId>_<manifestId>.txt` lists every path plus total files/bytes, which is enough to plan packaging. Add `-depot <id> -manifest <id>` to pin a specific manifest, and drop `-manifest-only` to actually fetch a depot's files.

**How to apply:** Prefer this over guessing from PCGamingWiki/store pages when a plan needs the real file layout of an owned Steam game. `scripts/prefetch/prefetch_steam.sh` takes `--appId/--depotId/--manifestId/--filelist` once hashes need prefetching.
