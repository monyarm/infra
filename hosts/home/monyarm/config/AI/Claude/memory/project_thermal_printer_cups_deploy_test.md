---
name: project_thermal_printer_cups_deploy_test
description: "2026-11-16 thermal printer test, both blank-print causes: cupsd empty stdin (spool-path fallback) and S&D emitting a single 76-row raster the firmware silently drops (tp.py now splits into ≤24-row bands); user confirmed the test sheet prints"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T19:09:21.457Z
---

Thermal printer (dp-l1s) post-deploy testing, 2026-11-16 evening.

State:
- Approx. 19:01 EET the deployed systemd unit `thermal-printer-dp-l1s-link.service` was active (running) and holding the Bluetooth link; CUPS was up with no system default destination, printer `dp-l1s` accepting and idle, device `thermal://55-55-09-55-C2-D6`.
- Bluetooth state for `55:55:09:55:C2:D6` (name `DP_L1S_C2D6`) was `Paired: yes`, `Bonded: no`, `Connected: yes`, `Trusted: no`. The agent ran no `pair` command during that session — blueman or an earlier manual step set the paired flag. So "paired" on this unit is not evidence of anything the tooling does, and paired-without-bonding is the observed normal here.
- User hardware report: direct `tp` text output worked, and so did the raster PNG; the two `lp -d dp-l1s` jobs (text file, PDF) only produced a paper feed and printed nothing.
- Blank-cause #1 (from cupsd source): on a local raw queue with a single file, cupsd inserts no filter, and its job code only wires the backend's stdin to a filter pipe — with no filter that fd stays -1 and process.c substitutes `/dev/null`. The backend therefore got empty stdin while the spool file was passed as the last argument. The feed still appeared because an empty-body text job still emits `ESC J`. Fix in `packages/tp.py`: after reading stdin, if it is empty, take the spool path from the last argument.
- Blank-cause #2 (2026-11-16, the S&D sheets): S&D's CUPS printer emits one single `GS v 0` raster for the whole page (~76 rows); this firmware silently drops any raster taller than 24 rows, so only the trailing feed ran and the sheet came out blank. Fix in `packages/tp.py`: `split_escpos()` re-bands incoming ESC/POS rasters into ≤24-row bands before sending.
- Verified: a direct backend test of the re-banding build printed (rc=0, one 48x76 raster → 3661 bytes) and the user confirmed the sheet "printed fine". `/api/print` through the real queue still needs the next `./deploy.sh` because `ServerBin` held the old `tp` store path.
- Jobs submitted with `lp` run as user `lp` through the cupsd daemon socket, so they do not exercise whether the unprivileged `lp` user can open the RFCOMM link itself.

**Why:** the pairing flag and the lp-via-daemon path both mislead if read as verification of the link-holder design; only direct `tp` runs from the user's own session prove the RFCOMM path, and even those say nothing about whether CUPS delivers data to the backend at all.

**How to apply:** when checking the printer, look at the user's own `tp` results, not at `Paired:` or at `lp`/CUPS job exit codes (exit 0 / "job completed" proves nothing about printing). A lone paper feed with no content means either empty stdin (check tp.py's spool-path fallback) or an over-tall single raster (check the band split).
