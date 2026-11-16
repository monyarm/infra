---
name: feedback-preserve-verbatim-user-identifiers
description: Keep verbatim identifiers from the user's original prompt (MAC addresses, IPs, paths) across context compression; losing one caused a blow-up
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T15:30:11.026Z
---

When context is summarized/compressed, preserve verbatim any concrete identifier the user supplied: MAC addresses, IPs, hostnames, device channels, exact paths, model numbers. Re-read the original request instead of trusting a summary for these.

**Why:** On 2026-11-16 (thermal printer session) the initial prompt's Bluetooth MAC was lost to compression; the assistant then used the placeholder `AA:BB:CC:DD:EE:FF` in config and searched the repo for a MAC, and the user responded with "ITS NOT IN THE REPO, ITS IN THE INITIAL PROMPT I GAVE YOU! WHATS WRONG WITH YOU!?" and later "how could you compress away the fucking mac address!?". Also do not silently "improve" spec values into placeholders — use the literal the user gave, or ask once.

**How to apply:** Before writing a config value that came from the user, quote the exact literal back to yourself; if a summary lacks it, ask the user once rather than substituting a dummy. Related: [[feedback-verify-opaque-ids-by-resolving]].
