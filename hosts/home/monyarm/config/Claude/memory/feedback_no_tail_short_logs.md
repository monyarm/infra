______________________________________________________________________

## name: feedback-no-tail-short-logs description: "Don't pipe moderately-short command output through `tail`, and don't wrap commands in `timeout` by default — both hide whether something is actually progressing." metadata: node_type: memory type: feedback originSessionId: 2f2a8057-2d8f-4802-8ae5-e17325ec1b10

Don't append `| tail -N` to commands whose output is already short-to-moderate (a few dozen
to ~100 lines) just out of habit for context economy. Don't reflexively wrap commands
(especially `nix build`/eval) in `timeout NNN` either.

**Why:** The user found `tail` made it unclear whether a long-running command (e.g. a `nix build`) was actually progressing or stuck, since intermediate/short output was being hidden
needlessly. Reiterated a second time specifically calling out `timeout`: it "just makes
things fail and makes it impossible to tell if it's doing anything" — a build that's still
legitimately working gets killed and reads as a failure instead of as "still running."

**How to apply:** Only truncate output that's genuinely large/unbounded (e.g. a full `nix build` derivation graph download log, a multi-thousand-line trace). For anything shorter,
let the full output through so progress and errors are visible as they happen. For commands
that might run long (builds, fetches), prefer `run_in_background` (and Monitor/notification)
over `timeout` — let it actually finish rather than guessing a deadline and killing it.

This covers `head` too, not just `tail` — swapping one truncation habit for the other after
being corrected still hides the same progress/error visibility. The user called this out
explicitly after it happened. Same applies to any other reflexive line-limiting (`| sed -n`,
`| grep -m N`, manual slicing) used out of context-economy habit rather than because the
output is actually unbounded.
