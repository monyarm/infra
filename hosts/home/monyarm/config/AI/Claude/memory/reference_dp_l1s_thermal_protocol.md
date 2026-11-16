---
name: reference_dp_l1s_thermal_protocol
description: Where to research the DP-L1S/C&Co 3128 thermal printer protocol, plus verified 2026-11-16 status-query replies, RFCOMM failure modes, the 24-row raster-height limit, feed/print commands, CUPS device-uri constraints and raw-queue backend stdin behaviour
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T19:09:38.036Z
---

Where to research the DP-L1S / SwitchOn 4326 / Crafts&Co (C&Co) 3128 thermal receipt printer protocol:
- `https://github.com/EloiGattet/tronic-lidl-thermal-printer/blob/main/PROTOCOL.md` (BLE-focused protocol notes)
- Reverse-engineered docs from the decompiled Lucky Jingle APK `com.dingdang.newprint` (SDK class `DP_L1S`)

Verified facts (2026-11-16):
- ESC/POS over classic Bluetooth SPP/RFCOMM works from an unprivileged user with no pairing; tested unit is `55:55:09:55:C2:D6` (device name `DP_L1S_C2D6`), channel 1.
- The live test unit identifies as model `L1S-HTC`, firmware `V1.09`, serial `L1SHTC235300641`.
- Raster height limit: the firmware silently drops any `GS v 0` raster taller than 24 rows — it does not error, it just prints nothing (a job with a single tall raster only shows the trailing feed). Rasters must be split into ≤24-row bands. This is what made Sales & Dungeons sheets come out blank (S&D emits one raster for the whole ~76-row page).
- Status/info queries all answer over SPP: model, firmware, serial, battery, status (`ready`), density (raw `01 0c 01`), shutdown/off timer (reads back as `20 min`). The speed query gets no reply. A joined all-fields reply echoes `DP_L1S_C2D6|<mac>|<second mac>|V1.09|<serial>|<battery%>`.
- Battery query `10 FF 50 F1` only answers when wrapped with the enable command + twelve `0x00` wake bytes; reply is 2 bytes: `00 <percent>`. Below ~22% the unit refuses to print (red flashing LED is the only other cue).
- Status byte query `10 FF 40` does not report the low-battery condition.
- Opening a fresh RFCOMM connection while the printer is still busy with a previous job fails: `[Errno 104] Connection reset by peer`, then `[Errno 103] Software caused connection abort`. Jobs spaced ~5 s apart are clean, so it is the printer's busy state, not the link, that rejects the new session. Holding one connection open across back-to-back jobs avoids it entirely.
- Printing is raster-only (GS v 0 bands), so text fonts are drawn client-side with PIL from system font paths; the printer has no font of its own. Head width is 384 dots, so monospace column count must be derived from the chosen font's metrics (`CELL = round(font.getlength("W"))`, `COLUMNS = 384 // CELL`) rather than hardcoded.
- A form-feed/line-feed `1B 4A 50` (80 dots ≈ 10 mm) is sent before closing the socket to push the last printed line clear of the head; without it the final line sits inside the mechanism.
- CUPS queues for this printer use a raw queue with a custom `thermal://` device-uri whose netloc is the MAC. `lpadmin` parses the device-uri as `scheme://host[:port]`, so a colon-separated MAC makes it fail with `lpadmin: Bad device-uri "thermal://55:55:09:55:C2:D6"` (verified locally against the same cupsd, exit code 1); `thermal://55-55-09-...` (dashes) is accepted. Any code matching MACs therefore has to fold the dashes back to colons. Raw queues also print a deprecation warning but still work.
- Raw-queue backend invocation gotcha (cupsd 2.4.19, verified from source): a local raw queue with a single input file gets no filter inserted, so the backend's stdin is `/dev/null` — the spool filename arrives as the last argv entry, with `argv[0]` being the device-uri. A backend that only reads stdin sees empty input; a text job like that still feeds because an empty body still emits `ESC J`. Backends must therefore fall back to the trailing spool-file argument when stdin is empty. CUPS reports such jobs as completed, so `lp` exit 0 does not prove anything printed.
