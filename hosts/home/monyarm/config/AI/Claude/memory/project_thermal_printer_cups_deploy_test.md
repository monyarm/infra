---
name: project-thermal-printer-cups-deploy-test
description: "2026-11-16 thermal printer test: direct tp text + raster worked, the two lp jobs only fed paper; root cause was cupsd handing the backend empty stdin (fix added to tp.py, awaiting redeploy + confirmation)"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T17:14:03.704Z
---

Thermal printer (dp-l1s) post-deploy testing, 2026-11-16 evening:
- Approx. 19:01 EET the deployed systemd unit `thermal-printer-dp-l1s-link.service` was active (running) and holding the Bluetooth link; CUPS was up with no system default destination, printer `dp-l1s` accepting and idle, device `thermal://55-55-09-55-C2-D6`.
- Bluetooth state for `55:55:09:55:C2:D6` (name `DP_L1S_C2D6`) was `Paired: yes`, `Bonded: no`, `Connected: yes`, `Trusted: no`. The agent ran no `pair` command during that session — blueman or an earlier manual step set the paired flag. So "paired" on this unit is not evidence of anything the tooling does, and paired-without-bonding is the observed normal here.
- User hardware report: direct `tp` text output worked, and so did the raster PNG; the two `lp -d dp-l1s` jobs (text file, PDF) only produced a paper feed and printed nothing.
- Diagnosis (from cupsd source): on a local raw queue with a single file, cupsd inserts no filter, and its job code only wires the backend's stdin to a filter pipe — with no filter that fd stays -1 and process.c substitutes `/dev/null`. The backend therefore got empty stdin while the spool file was passed as the last argument. The feed still appeared because an empty-body text job still emits `ESC J`.
- Fix (uncommitted) in `packages/tp.py`: after reading stdin, if it is empty, take the spool path from the last argument. Verified locally by reproducing the exact CUPS invocation shape (stdin `/dev/null`, spool path as last arg) with a text file and a PDF, both exit 0.
- Not yet proven: the live queue still pointed at the old store path in `ServerBin`, so `./deploy.sh gaming-laptop` plus a real `lp` run was still needed; no commit was made until the user confirms the `lp` jobs actually print.
- Jobs submitted with `lp` run as user `lp` through the cupsd daemon socket, so they do not exercise the open question of whether the unprivileged `lp` user can open the RFCOMM link itself.

**Why:** the pairing flag and the lp-via-daemon path both mislead if read as verification of the link-holder design; only direct `tp` runs from the user's own session prove the RFCOMM path, and even those say nothing about whether CUPS delivers data to the backend at all.

**How to apply:** when checking the printer, look at the user's own `tp` results, not at `Paired:` or at `lp`/CUPS job exit codes (exit 0 / "job completed" proves nothing about printing). A lone paper feed with no content means the backend saw empty stdin — check tp.py's spool-path fallback.
