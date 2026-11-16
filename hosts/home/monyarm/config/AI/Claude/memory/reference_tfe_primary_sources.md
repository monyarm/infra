---
name: reference-tfe-primary-sources
description: "Where to research The Force Engine: GitHub repo/API, official site, df-21.net mod hub, in-tree Documentation (manual + remaster cutscenes)"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-13T17:02:44.769Z
---

The Force Engine (TFE), the Dark Forces engine reimplementation planned for this repo, is researched from these primary sources:
- github.com/TheForceEngine/TheForceEngine — releases, `Roadmap.md`, `README.md`, and `Documentation/` (`TheForceEngineManual.md`, `TheForceEngine.md`, `remaster-cutscenes/`); the GitHub REST API (`/repos/.../releases`) gives exact tag + date quickly.
- theforceengine.github.io — landing page, `downloads.html`, and dated dev/retrospective blog posts.
- df-21.net — the Dark Forces mod/mission hub (`/downloads/`, missions table, Hall of Fame); useful for level packs and DOS-era campaigns.
- ModDB's page for TFE is Cloudflare-blocked to plain fetching (returns a JS challenge page), so prefer the above.

Linux packaging note from that research: TFE publishes Windows-only release zips (no official Linux artifacts); the practical install route is Flathub `io.github.theforceengine.tfe`, otherwise a CMake build (SDL2 ≥2.24, SDL2_image, OpenGL 3.3).
