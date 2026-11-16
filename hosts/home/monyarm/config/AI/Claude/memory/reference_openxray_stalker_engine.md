---
name: reference_openxray-stalker-engine
description: "Where to research OpenXRay and verified 2026-11-14 findings: CoP/CS only (SoC unsupported), CLI game selection, Linux data layout, Anomaly/GAMMA are xray-monolith forks"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-13T23:15:00.935Z
---

OpenXRay (github.com/OpenXRay/xray-16) research, verified 2026-11-14.

Where to look:
- Repo wiki pages: `[EN]-Differences-from-original-X-Ray`, `[EN]-Engine's-command-line-keys`, `[EN]-How-to-build-and-setup-on-Linux-and-MacOS`, install-playing page.
- GitHub API for tags/releases, commits, and issue search/`issues/NNN` (issues carry the real compatibility answers).
- `github.com/themrdemonized/xray-monolith` for Anomaly/GAMMA engine; `OGSR/OGSR-Engine` and IX-Ray (`ixray-1.6-stcop`, `ixray-1.5-stcs`) as SoC-side alternatives.

Verified facts:
- Refactored X-Ray 1.6.02 (CoP engine, 2014 leak lineage), C++17/CMake/SDL2/OpenAL/OpenGL 4.1.
- Latest *stable* release is old: December 2021 RC1 (`1144-december-2021-rc1`, 2021-12-09), plus a rolling `latest-nightly` tag; development is active (last commit 2026-11-05), so distro packages track master, not a release.
- Game support: Call of Pripyat 1.6.02 = default, best supported. Clear Sky 1.5.10 = supported but needs an extra `gamedata.zip`. Call of Chernobyl = nightly only. **Shadow of Chernobyl = NOT supported** (pre-alpha, issue #392) — the common assumption that openxray covers "SoC/CS/CoP" is wrong.
- Selection is a CLI flag on `xr_3da`: `-cop` (default) / `-cs` / `-soc`; data via `-fsltx` override.
- Linux data layout: `levels localization mp patches resources` symlinked into `~/.local/share/GSC Game World/S.T.A.L.K.E.R. - <game>/` next to `fsgame.ltx`; GOG directory names must be lowercased.
- Rendering: DX11 ("DX11 in DX10 mode") on Windows, OpenGL elsewhere; original DX9/DX10 paths gone. Largely single-threaded still.
- Saves: Clear Sky original saves explicitly unsupported; CoP vanilla-save loading undocumented/unverified.
- Mods: Anomaly 1.5.2 and GAMMA run **xray-monolith**, based on OpenXRay's CoC edition but a separate Windows-only (VS2015) fork — not mainline. CoC works. SoC mods (OLR, AMK, OGSE) are out of reach. Enhanced Edition (2024-25 rereleases) unsupported (issue #1865).
- Linux rough edges: GL-only so slower than Windows, AMD GLSL water-shader bug only fixed 2026-10 (`c62d9d3`), AMD SSAO bugs, no save previews, non-UTF-8 logs/saves, OpenAL HRTF needs `~/.alsoftrc`, no native Wayland (XWayland via SDL2).
- Bottom line for owned CoP/CS/SoC: OpenXRay is the right pick for CoP (and workable for CS); SoC needs OGSR (Windows/D3D11) or Proton instead.

**Why:** Saves re-establishing which games the engine actually supports and its Linux data/CLI shape before packaging work starts.
**How to apply:** Confirm against the wiki/API again before wiring a derivation; treat the unverified items (CoP vanilla saves, native Wayland) as unknown, not settled.
