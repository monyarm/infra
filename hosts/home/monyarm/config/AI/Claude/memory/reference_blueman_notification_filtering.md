---
name: reference_blueman_notification_filtering
description: "Verified 2026-11-16: blueman 2.4.6 (nixpkgs, GSettings-backed org.blueman) can only mute connection notifications globally, not per device; user opted for global off"
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T15:54:39.511Z
---

Blueman connect/disconnect notifications come from its applet plugins, mainly `ConnectionNotifier` (`blueman/plugins/applet/ConnectionNotifier.py`). Verified 2026-11-16 on blueman 2.4.6 from nixpkgs:

- Plugin options are stored through Gio.Settings with schema `org.blueman.plugins`, one key per plugin (e.g. `connection-notifier`), so the only switch is a global per-plugin boolean.
- There is no per-device / per-MAC notification filter, and blueman ships no `share/glib-2.0/schemas` in its store output (schemas live with the desktop's GS settings).
- The notifier is loaded from the running applet, so a config change only takes effect on applet restart.

User's standing choice: since per-device muting is impossible, disable the connection notifications entirely (handled by `hosts/home/monyarm/config/Blueman.nix`) rather than adding a custom filter.
