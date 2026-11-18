---
name: project-nxm-mod-managers-r2modman-amethyst
description: "2026-11-17 nxm handling as HM module options: manager carries type/windows, nxm.games.<id> IS the manager key string (no .manager attr), our nxm-handler script owns nxm://+nxm-protocol, Stardrop dropped, MO2 kept for now but unreferenced, Amethyst the fallback; full set is 4 managers (amethyst, r2modman, fallout76, mo2) and 7 game ids"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-17T01:42:17.008Z
---

Requested 2026-11-17:

- Compare the repo's own `nxm` script/module against the `nxm` on the **monyarm@monyarm** host. Outcome: it is the same generated script, not a distinct hand-written one — the host's copy had been overwritten. Only old `/nix/store/*-nxm` copies remain; the older ones route ids `fallout76`, `r2modman`, `stardewvalley`, `tcgcardshopsimulator` (r2modman AppImage / Stardrop paths).
- User redirected the work: **make nxm handling a config option**, so a game module can define its own mod manager, and the manager definitions are config options too.
- Scope constraint that still stands: leave the existing **Windows-only** nxm handling exactly as it is.

Plan lives at `/home/monyarm/.opencode/plan/nxm-mod-managers.md` (not implemented). Original sketch: `nxm.managers.<name> = { package; binary; args; }`, `nxm.games.<id>.manager = "<name>"`, `command` escape hatch, `nxm.fallback` (was MO2 + wine).

**FINAL SHAPE 2026-11-17 (user-directed, authoritative; plan file holds it in a "FINAL SHAPE (authoritative — replaces every options sketch above)" section, superseding the earlier sketches):**

- `nxm.games.<id>` **is** the manager key string — `nxm.games.cyberpunk2077 = "amethyst"`. The user explicitly rejected `nxm.games.<id>.manager = …` ("no, no .manager, nxm.games.<id> = X"); there is one manager per game, and the value additionally carries no other data.
- All launch detail lives on the manager: `nxm.managers.<name> = { package; binary; args; type = "native" | "windows"; exe; prefix; wine; dotnet; desktopName; }`.
- Generated-script resolution: first path segment (`cut -d/ -f3`) → `nxm.games.<id>` → that manager's branch; unknown id walks `nxm.fallback` (now `[ "amethyst" ]`).
- Rendering: `native` → `exec <package>/bin/<binary> <args…> "$@"`; `windows` → today's `WINEPREFIX=… WINEESYNC=0 <wine> <exe> "$@"` verbatim.
- Scheme ownership: rename the generated script to `nxm-handler` plus a matching `.desktop` that owns `x-scheme-handler/nxm-protocol` **and** `x-scheme-handler/nxm`, with `nxm` kept only as a compatibility alias. **Our script owns `nxm://`, not Amethyst** — Amethyst is only the fallback target.
- Two forced structural changes: `config/XDG.nix`'s `lists.nxm = [ "modorganizer2-nxm.desktop" ]` is stale and must point at the new desktop file; `config/Bin/nxm.nix` stops being `(import ./nxm.nix { inherit pkgs dirs; })` in `config/Bin/default.nix` and becomes a real HM module — otherwise nothing can extend `nxm.managers`/`nxm.games` from a game module.
- Packaging: r2modman via `appimageTools.wrapType2` on `r2modman-3.2.21.AppImage`; Amethyst as its own derivation cribbing `a4blue/Amethyst-Mod-Manager-Nix-Packaging` and `Briaoeuidhtns/amethyst-nix`.

**Full set the module defines (refined 2026-11-17, final), 4 managers + 7 games:**

- Managers: `amethyst` (`pkgs.amethyst`, new Python derivation, `native`, default for everything); `r2modman` (`pkgs.r2modman`, new AppImage wrap, `native`, Thunderstore manager); `fallout76` (`windows`, `Fo76ini.exe` under GE-Proton with `WINEPREFIX=${dirs.MediaSSD}/Bethesda/WINEPREFIX`) — the user clarified the 76 tool *is* a mod manager for Fallout 76, so it stays; `mo2` (`windows`, `MO2/nxmhandler.exe` under GE-Proton) — **kept for now** on the user's instruction ("still keep MO2's for now") after it had been dropped, explicitly flagged in the plan as currently unreferenced.
- Games on `amethyst`: `cyberpunk2077`, `oblivion`, `stardewvalley` (Stardrop dropped), `dressmaker`, `kotamon`, `grandtheftautovicecity`.
- `fallout76` → `fallout76`.
- `tcgcardshopsimulator` **dropped** at the user's request ("drop tcgcardshop for now").
- Nothing points at `mo2`; unknown ids still go to Amethyst. The `windows` code path is used by both the Fo76 and MO2 managers.

**Why:** the repo already has an nxm/mime path; the goal is parity with the other host's managers and letting each game module declare its own manager instead of one hard-coded dispatch. Putting type/windows on the manager avoids per-game duplication since every Amethyst-managed title is covered by one entry. MO2 is kept so it stays available if the user later wants to point a game at it.

**How to apply:** read `config/Bin/nxm.nix` and the plan file first; keep the Windows branch verbatim; don't assume a title is or isn't a Nexus game — check the manager's own config, and remember the script owns the scheme, not Amethyst.
