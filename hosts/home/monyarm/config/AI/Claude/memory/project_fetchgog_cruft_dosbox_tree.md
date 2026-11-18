---
name: project_fetchgog_cruft_dosbox_tree
description: "2026-11-17 finding: fetchGOG's gogCruft deletes the DOSBOX/dosbox/app/DOSBOX trees that hold GOG DOS game data (only __support/dosbox*.conf is kept, and it is a GOG-layout template); user decided the cruft list stays as-is for now and only gains a parameter if the need arises"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T23:46:43.133Z
---

**Fact (2026-11-17):** `lib/fetchers/gog.nix`'s `gogCruft = baseCruft ++ [ "scummvm" "ScummVM" "DOSBOX" "dosbox" "app/DOSBOX" ... "tmp" "__support/!dosbox*.conf" "commonappdata" ]` deletes the `DOSBOX`/`dosbox`/`app/DOSBOX` trees outright. On a GOG DOS title those directories are often exactly where the game data lives, so the list is ScummVM-tuned and unsafe for the DOS titles (its source comment says as much). The `!` prefix is a keep-negation, so `__support/dosbox<Game>.conf` is deliberately retained while the rest of `__support/` (manual, gamepad mapper) is dropped.

**Also:** the kept `__support/dosbox*.conf` is a *template*, not a usable config — it hardcodes GOG's own install layout (`mount C` pointing at their directory naming), so it has to be regenerated for this repo's mount paths regardless.

**User decision (2026-11-17):** the cruft list stays as it is for now; it only gets a parameter (editable cruft / DOS-safe mode) if the need actually arises when DOS titles land. So do not pre-emptively refactor `gogCruft` — but keep the fix in mind for the first DOS title.

**Why:** the user asked whether cruft removal would throw away the DOSBox config needed for future DOS games; the answer is the config survives but the data directories next to it do not.
**How to apply:** when the first DOS title lands, propose giving `fetchGOG` a `cruft ? gogCruft` parameter (or a `baseCruft`-only mode) so DOS releases keep the DOSBOX tree; treat the preserved conf as a template to rewrite rather than a config to reuse.
