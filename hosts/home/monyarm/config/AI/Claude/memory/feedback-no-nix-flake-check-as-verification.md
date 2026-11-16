---
name: feedback-no-nix-flake-check-as-verification
description: Never run `nix flake check` just to verify a change — the user says it takes forever; build/eval only the touched outputs
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T15:30:11.024Z
---

Do not run `nix flake check` as a verification step. On 2026-11-16 the user interrupted with "WOAH! DO NOT RUN NIX THROUGH TAIL OR DO NIX FLAKE CHECK WHICH WILL TAKE FUCKING FOREVER". Verify by building/evaluating only the specific derivations or module attrs touched.

**Why:** A full flake check on this repo evaluates every configuration and takes an extremely long time; the user considers it wasted time, not validation.

**How to apply:** For package/module work, use targeted `nix eval` attr lookups and `nix build` of just the new/changed derivation. `AGENTS.md` mentions `nix flake check --impure` as repo validation — treat that as documentation of how the check works, not a routine command to run. Related: [[feedback-no-full-toplevel-build-for-verification]], [[feedback-no-tail-short-logs]] (same message: also no pipes/truncation on nix output).
