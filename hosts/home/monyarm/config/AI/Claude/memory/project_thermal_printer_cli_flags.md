---
name: project-thermal-printer-cli-flags
description: "Thermal printer print tool (tp): short+long flags (-c/-f/-s/-t/-z), --size 20, trim on by default with --no-trim, --no-feed/--feed N with 80 as default (60 too hard to rip); pre-text blank gap is firmware, not code"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T16:18:27.593Z
---

As of 2026-11-16 the thermal printer print tool (`tp`) exposes:
- `--size N` / `-s PX` — default 20; recomputes cell pitch and column count for monospace (`384 // round(advance)`), so size 24 wraps at 27 columns
- `--trim` on by default (leading + trailing blank lines dropped) with `--no-trim` to keep them; `-t` short form
- `--no-feed` and `--feed N` / `-z DOTS` — N in dots, accepted range 0–255; **default is 80 dots**. The user first settled on 60, then reverted the same day: "set it back to 80… 60 is a bit hard to rip". Do not lower the default again without a fresh hardware verdict.
- `-c/--center`, `-f/--font NAME|FILE`, `-h/--help`, plus existing `-i/--info`, `--serve`, `--mac`, `--channel`

**Why:** hardware tests on 2026-11-16 settled the trailing-feed question: the feed IS needed to push the sheet out (without it the last line does not clear the head); trimming whitespace only is safe as a default; 60 dots tears off too tight on this unit.

**How to apply:** keep feed behaviour selectable (not baked in), default `FEED_DOTS = 80`, and re-send a test print only if the user asks.

Pre-text blank gap (investigated 2026-11-16, now closed):
- The user wanted the blank feed/gap printed *before* the text removed. Two sheets were sent to isolate it: the normal path (battery gate sends `10 FF F1 03` + 12 nulls first) and a no-wake path (raw socket, bands straight in, no enable/wake, no battery query), the latter re-sent with feed 60.
- Result: skipping the wake/enable block "didn't affect the pre-text feed" — the leading gap is unchanged, and the user concluded it is in the firmware. Do not re-open this as a client-code bug without new evidence.
