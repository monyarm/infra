---
name: feedback_thermal_link_holder_over_waits
description: For the DP-L1S printer, the user chose a persistent connection daemon over wait/retry delays, explicitly reversing the earlier no-daemon/no-link-holder constraint
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T15:54:39.449Z
---

For the thermal printer tooling, prefer a daemon that holds the RFCOMM connection open across jobs (idle-disconnecting only after a timeout) over adding wait/retry delays around each print.

**Why:** the user said "I know the initial prompt said not daemon or link-holder, but I'm giving you new instructions now… I think it's better than adding waits that slow the whole thing down." Waits penalise every print; a held link costs nothing while idle.

**How to apply:** treat the original "no daemon / no link-holder" constraint as superseded for this project — don't re-litigate it, and don't answer a connection-reset problem with longer sleeps.
