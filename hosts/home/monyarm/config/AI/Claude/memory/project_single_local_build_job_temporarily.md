---
name: project-single-local-build-job-temporarily
description: As of 2026-11-13 the user has other work running on the PC, so run nix builds with a single local job (--max-jobs 1); remote builders are still fine — temporary
metadata:
  type: project
  origin: opencode
  modified: 2026-11-13T21:29:28.943Z
---

Temporary build constraint (stated 2026-11-13): the user has other stuff running on their PC, so future nix builds should use a single local job — `--max-jobs 1`. Remote builders are explicitly still allowed ("builders are fine").

**Why:** Competing local builds were starving the rest of the machine.

**How to apply:** Add `--max-jobs 1` to `nix build`/similar invocations until the user lifts the constraint; do not disable remote builders. Re-check with the user before going back to parallel local jobs.
