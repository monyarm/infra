---
name: feedback-background-task-pattern
description: "Avoid nohup+redirect-to-logfile+poll-until-string wrapper scripts for long-running Bash commands; use the Bash tool's own run_in_background instead."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5ac9d091-64cb-4c8b-bf5a-bdba0522e8d0
---

Don't wrap long-running shell commands in `nohup ... > logfile 2>&1 &; disown` (or
plain `&` backgrounding) plus a separate `until grep -q DONE logfile; do sleep 5;
done` / Monitor polling loop. The user called this pattern "sloppy" once, and hit it
again later in a different session (manually backgrounded a slow
`update-sources.py` run with `&` + log redirect, then re-armed a Monitor to poll
it) — direct feedback: "That was dumb, detaching it rather than doing it as one of
your shells... makin git so I cant look at it's log". A manually `&`-detached
process is invisible to the user's own tooling; only a `run_in_background: true`
Bash task is inspectable by them directly.

**Why:** The Bash tool already supports `run_in_background: true` directly on the
real command, which gives a harness-managed output file and an automatic
task-notification on completion — no manual log file, sentinel string, or poll loop
needed, and critically, it stays visible/inspectable to the user the same way it is
to you.

**How to apply:** For any long-running command (nix builds, fetch scripts, etc.),
call Bash with `run_in_background: true` on the actual command itself, then wait for
the task-notification and Read the returned output file path. Only reach for
redirecting to a file in the repo when a command's own output would otherwise be
lost (e.g. because it must run detached from the tool's stdout capture) — not as a
default habit, and never as a substitute for `run_in_background: true` just because
the command might run long.
