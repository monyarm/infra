---
name: feedback-single-printer-defaults-to-it
description: "Thermal printer: default to the single configured device, no MAC/device selector until a second printer exists"
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T15:30:23.278Z
---

For the thermal-printer module (`services.thermalPrinters`), the user does not want a MAC/device selector option while only one thermal printer is configured: `tp` should default to that single printer, and target selection can be added later if multiple printers exist. As of 2026-11-16 the only unit is DP-L1S at `55:55:09:55:C2:D6`, channel 1.

**Why:** "the mac address, that's redundant for right now, since we only have one thermal printer setup. If there's one, it just defaults to it, if there's multiple, then we can worry about it and add a way to select one."

**How to apply:** Don't build multi-device selection UI/options proactively. When a second printer appears, revisit and ask how it should be chosen.
