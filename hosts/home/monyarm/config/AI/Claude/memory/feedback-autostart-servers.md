---
name: feedback-autostart-servers
description: When something packaged turns out to be a long-running server, add a systemd (user) unit with autostart instead of leaving it as a bare command
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T20:59:15.255Z
---

If a tool the user runs is a server (a daemon serving an address), wire it up to autostart rather than leaving it as a command to launch by hand — for per-user web apps/services, a `systemd.user.services.<name>` with `WantedBy = [ "default.target" ]`.

**Why:** the user's words on 2026-11-16 about the S&D (`snd`) server: "oh, if its a server, make it autostart". A server that only runs when manually launched isn't "packaged" in the sense the user expects.

**How to apply:** after discovering a packaged tool is a headless server (e.g. it opens a port instead of a window), add the user service unit in the module that already configures that tool (e.g. `hosts/home/monyarm/config/Snd.nix`), with `Restart = "on-failure"` for intermittent crashes. This is a config change, not permission to run activation — see feedback_no_unasked_activation. Tell the user a deploy is needed before the unit exists, and don't assume autostart implies auto-seeding state (mutating their data is still opt-in).
