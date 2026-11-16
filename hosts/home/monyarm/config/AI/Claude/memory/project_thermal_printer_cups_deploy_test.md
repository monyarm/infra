---
name: project_thermal_printer_cups_deploy_test
description: "2026-11-16 thermal printer test: both blank-print causes (cupsd empty stdin, over-tall single raster), then post-deploy verification of all five print routes (CLI text, CLI raster, CUPS txt, CUPS PDF, S&D /api/print via CUPS raw) with the split_escpos backend live"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T20:10:57.563Z
---

Thermal printer (dp-l1s) testing around the 2026-11-16 deploy.

Pre-deploy state:
- Approx. 19:01 EET the deployed systemd unit `thermal-printer-dp-l1s-link.service` was active (running) and holding the Bluetooth link; CUPS was up with no system default destination, printer `dp-l1s` accepting and idle, device `thermal://55-55-09-55-C2-D6`.
- Bluetooth state for `55:55:09:55:C2:D6` (name `DP_L1S_C2D6`) was `Paired: yes`, `Bonded: no`, `Connected: yes`, `Trusted: no`. The agent ran no `pair` command during that session — blueman or an earlier manual step set the paired flag. So "paired" on this unit is not evidence of anything the tooling does, and paired-without-bonding is the observed normal here.
- User hardware report: direct `tp` text output worked, and so did the raster PNG; the two `lp -d dp-l1s` jobs (text file, PDF) only produced a paper feed and printed nothing.
- Blank-cause #1 (from cupsd source): on a local raw queue with a single file, cupsd inserts no filter, and its job code only wires the backend's stdin to a filter pipe — with no filter that fd stays -1 and process.c substitutes `/dev/null`. The backend therefore got empty stdin while the spool file was passed as the last argument. The feed still appeared because an empty-body text job still emits `ESC J`. Fix in `packages/tp.py`: after reading stdin, if it is empty, take the spool path from the last argument.
- Blank-cause #2 (2026-11-16, the S&D sheets): S&D's CUPS printer emits one single `GS v 0` raster for the whole page (~76 rows); this firmware silently drops any raster taller than 24 rows, so only the trailing feed ran and the sheet came out blank. Fix in `packages/tp.py`: `split_escpos()` re-bands incoming ESC/POS rasters into ≤24-row bands before sending.
- A direct backend test of the re-banding build printed (rc=0, one 48x76 raster → 3661 bytes) and the user confirmed that sheet "printed fine".
- Jobs submitted with `lp` run as user `lp` through the cupsd daemon socket, so they do not exercise whether the unprivileged `lp` user can open the RFCOMM link itself.

Post-deploy (2026-11-16 evening, after the user said "I've deployed"):
- Deployed backend is `/nix/store/vzwd3z90c93q6hw77bz2cwn7nwj3rg8p-tp` and it contains `split_escpos`, so the re-banding path is live in the real queue. Queue state: `dp-l1s` accepting, device `thermal://55-55-09-55-C2-D6`, `/run/current-system/sw/bin/tp` on PATH.
- While the printer was powered off, `tp` failed with `[Errno 112] Host is down` (rc=1); powering the printer back on cleared it and both text and image runs returned rc=0.
- Five sheets submitted: `printf ... | tp` (CLI text → link-holder daemon, rc=0), `tp tp_raster_test.png` (rc=0), `lp -d dp-l1s tp_cups.txt` (CUPS → backend, job `dp-l1s-5`), `lp -d dp-l1s tp-test.pdf` (CUPS → PDF text path, job `dp-l1s-6`), and S&D `/api/print` HTML (S&D → CUPS raw → re-banded, job `dp-l1s-7`, 4096 B).
- Status at end of session: the agent asked the user whether all five printed correctly (S&D sheet included); no on-paper confirmation of the post-deploy set in the transcript, so treat the S&D-through-the-real-queue re-test as still pending confirmation.

**Why:** the pairing flag and the lp-via-daemon path both mislead if read as verification of the link-holder design; only direct `tp` runs from the user's own session prove the RFCOMM path, and even those say nothing about whether CUPS delivers data to the backend at all.

**How to apply:** when checking the printer, look at the user's own `tp` results, not at `Paired:` or at `lp`/CUPS job exit codes (exit 0 / "job completed" proves nothing about printing). A lone paper feed with no content means either empty stdin (check tp.py's spool-path fallback) or an over-tall single raster (check the band split). `Errno 112 Host is down` just means the printer is switched off.
