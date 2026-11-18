---
name: reference_dp_l1s_thermal_protocol.md
description: Where to research the DP-L1S/C&Co 3128 thermal printer protocol, plus verified 2026-11-16 status-query replies, RFCOMM failure modes, the 24-row raster-height limit and per-job buffer ceiling, page chunking with ESC @ (no inter-page feed), feed/print commands, CUPS device-uri constraints, raw-queue backend stdin behaviour, and why Chrome's own print dialog rejects raw queues while CUPS advertises every paper size
metadata:
  type: reference
  origin: opencode
  modified: 2026-11-16T21:34:45.531Z
---

Where to research the DP-L1S / SwitchOn 4326 / Crafts&Co (C&Co) 3128 thermal receipt printer protocol:
- `https://github.com/EloiGattet/tronic-lidl-thermal-printer/blob/main/PROTOCOL.md` (BLE-focused protocol notes)
- Reverse-engineered docs from the decompiled Lucky Jingle APK `com.dingdang.newprint` (SDK class `DP_L1S`)

Verified facts (2026-11-16):
- ESC/POS over classic Bluetooth SPP/RFCOMM works from an unprivileged user with no pairing; tested unit is `55:55:09:55:C2:D6` (device name `DP_L1S_C2D6`), channel 1.
- The live test unit identifies as model `L1S-HTC`, firmware `V1.09`, serial `L1SHTC235300641`.
- Raster height limit: the firmware silently drops any `GS v 0` raster taller than 24 rows — it does not error, it just prints nothing (a job with a single tall raster only shows the trailing feed). Rasters must be split into ≤24-row bands. This is what made Sales & Dungeons sheets come out blank (S&D emits one raster for the whole ~76-row page).
- Print-job buffer ceiling: even banded, the firmware stops draining the link once a job's buffered image fills (observed cutting off around ~55–66 lines / the equivalent of a few dozen rows of paper depending on banding). One `GS v 0` job cannot print an arbitrarily long page; the long text has to be split into pages (empirically `PAGE_LINES = 40` text lines per job) with one job per page.
- Resetting the buffer between pages: `ESC @` (init) ends a non-final job without moving the paper, so consecutive pages join seamlessly with no visible gap — verified: 100-line document printed continuously with only the final 80-dot feed. A feed between pages is the wrong fix (it advances paper mid-document).
- Back-to-back print jobs need spacing: firing pages immediately one after another resets the connection with `ETIMEDOUT`; ~3 s (`PAGE_DELAY = 3`) between jobs is clean. A job that hangs can also surface as a client-side read timeout, so a timeout is not proof the page did not print (the user saw output up to ~55 when the client had already timed out).
- Status/info queries all answer over SPP: model, firmware, serial, battery, status (`ready`), density (raw `01 0c 01`), shutdown/off timer (reads back as `20 min`). The speed query gets no reply. A joined all-fields reply echoes `DP_L1S_C2D6|<mac>|<second mac>|V1.09|<serial>|<battery%>`.
- Battery query `10 FF 50 F1` only answers when wrapped with the enable command + twelve `0x00` wake bytes; reply is 2 bytes: `00 <percent>`. Below ~22% the unit refuses to print (red flashing LED is the only other cue).
- Status byte query `10 FF 40` does not report the low-battery condition.
- Opening a fresh RFCOMM connection while the printer is still busy with a previous job fails: `[Errno 104] Connection reset by peer`, then `[Errno 103] Software caused connection abort`. Jobs spaced ~5 s apart are clean, so it is the printer's busy state, not the link, that rejects the new session. Holding one connection open across back-to-back jobs avoids it entirely.
- Printing is raster-only (GS v 0 bands), so text fonts are drawn client-side with PIL from system font paths; the printer has no font of its own. Head width is 384 dots, so monospace column count must be derived from the chosen font's metrics (`CELL = round(font.getlength("W"))`, `COLUMNS = 384 // CELL`) rather than hardcoded.
- A form-feed/line-feed `1B 4A 50` (80 dots ≈ 10 mm) is sent before closing the socket to push the last printed line clear of the head; without it the final line sits inside the mechanism.
- CUPS queues for this printer use a raw queue with a custom `thermal://` device-uri whose netloc is the MAC. `lpadmin` parses the device-uri as `scheme://host[:port]`, so a colon-separated MAC makes it fail with `lpadmin: Bad device-uri "thermal://55:55:09:55:C2:D6"` (verified locally against the same cupsd, exit code 1); `thermal://55-55-09-...` (dashes) is accepted. Any code matching MACs therefore has to fold the dashes back to colons. Raw queues also print a deprecation warning but still work.
- Raw-queue backend invocation gotcha (cupsd 2.4.19, verified from source): a local raw queue with a single input file gets no filter inserted, so the backend's stdin is `/dev/null` — the spool filename arrives as the last argv entry, with `argv[0]` being the device-uri. A backend that only reads stdin sees empty input; a text job like that still feeds because an empty body still emits `ESC J`. Backends must therefore fall back to the trailing spool-file argument when stdin is empty. CUPS reports such jobs as completed, so `lp` exit 0 does not prove anything printed.
- Client-side print dialogs: Chrome's built-in dialog lists only driver-backed queues, so a raw queue selected there fails with "selected printer is not available"; the system print dialog (Ctrl+Shift+P) works because it hands the job straight to cupsd. Verified working 2026-11-16.
- Paper-size selection cannot be narrowed on a raw queue: Chrome/GTK build the list from the queue's IPP `media-supported`, which cupsd derives from the PPD; with no PPD it advertises CUPS's generic full size set and there is no `lpadmin` option to restrict media. The only fix is giving the queue a PPD, which turns the pipeline on (CUPS converts PDF to `application/vnd.cups-raster`), so the backend would then need to unpack CUPS raster into 384-dot bands instead of receiving raw bytes.
