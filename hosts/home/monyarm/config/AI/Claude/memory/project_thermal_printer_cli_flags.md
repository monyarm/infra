---
name: project-thermal-printer-cli-flags
description: "Thermal printer print tool (tp): short+long flags (-c/-f/-s/-t/-z), --size 20, trim on by default with --no-trim, --no-feed/--feed N with 60 as default; pre-text blank gap ruled out as code side (firmware)"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T16:08:55.687Z
---

As of 2026-11-16 the user wants the thermal printer print tool (`tp`) to expose:
- `--size N` / `-s PX` — default 20; recomputes cell pitch and column count for monospace (`384 // round(advance)`), so size 24 wraps at 27 columns
- `--trim` on by default (leading + trailing blank lines dropped) with `--no-trim` to keep them; `-t` short form
- `--no-feed` and `--feed N` / `-z DOTS` — N in dots, accepted range 0–255 via the natural type; user confirmed on 2026-11-16 that **60 dots is just right**, so use 60 as the feed default (not the old hardcoded 80 / `1B 4A 50`)
- `-c/--center`, `-f/--font NAME|FILE`, `-h/--help`, plus existing `-i/--info`, `--serve`, `--mac`, `--channel`

**Why:** the hardware test on 2026-11-16 settled the trailing-feed question (the feed IS needed to push the sheet out; without it the last line does not clear), that trimming only whitespace is safe to make the default, and that 60 dots (vs 80) is the preferred feed amount. The user also asked for short one-letter forms for all the common flags.

**How to apply:** wire the flags with those defaults, keep feed behaviour selectable (not baked in), and re-send a test print only if the user asks.

Pre-text blank gap (investigated 2026-11-16, now closed):
- The user wanted the blank feed/gap printed *before* the text removed. Two sheets were sent to isolate it: the normal path (battery gate sends `10 FF F1 03` + 12 nulls first) and a no-wake path (raw socket, bands straight in, no enable/wake, no battery query), the latter re-sent with feed 60.
- Result: skipping the wake/enable block "didn't affect the pre-text feed" — the leading gap is unchanged, and the user concluded it is in the firmware. Do not re-open this as a client-code bug without new evidence.
