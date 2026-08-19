______________________________________________________________________

## name: feedback-background-task-pattern description: "Avoid nohup+redirect-to-logfile+poll-until-string wrapper scripts for long-running Bash commands; use the Bash tool's own run_in_background instead." metadata: node_type: memory type: feedback originSessionId: 2f2a8057-2d8f-4802-8ae5-e17325ec1b10

Don't wrap long-running shell commands in `nohup ... > logfile 2>&1 &; disown` plus a
separate `until grep -q DONE logfile; do sleep 5; done` polling command. The user
explicitly called this pattern "sloppy".

**Why:** The Bash tool already supports `run_in_background: true` directly on the
real command, which gives a harness-managed output file and an automatic
task-notification on completion — no manual log file, sentinel string, or poll loop
needed.

**How to apply:** For any long-running command (nix builds, fetch scripts, etc.),
call Bash with `run_in_background: true` on the actual command itself, then wait for
the task-notification and Read the returned output file path. Only reach for
redirecting to a file in the repo when a command's own output would otherwise be
lost (e.g. because it must run detached from the tool's stdout capture) — not as a
default habit.
