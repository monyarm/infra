---
name: project-single-local-build-job-temporarily
description: The 2026-11-13 temporary "--max-jobs 1" single local job constraint was lifted by the user on 2026-11-16 ("stop doing it as max-jobs 1") — stop forcing it on nix builds
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T18:35:09.310Z
---

Build job limit: LIFTED on 2026-11-16. The user said "stop doing it as max-jobs 1", reversing the 2026-11-13 temporary constraint that the assistant add `--max-jobs 1` to nix builds because other work was running on the PC.

**Why:** The user no longer wants builds throttled to a single local job.

**How to apply:** Do not add `--max-jobs 1` to `nix build`/`nix eval` invocations anymore; let Nix use its normal local parallelism. (Remote builders were always allowed.)
