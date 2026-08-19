______________________________________________________________________

## name: update-sources-full-run-danger description: Never run update-sources.py without --append unless user explicitly confirms in-the-moment; full runs re-resolve every source in sources.toml. metadata: node_type: memory type: feedback originSessionId: dd2c7cec-fbaa-4c55-bdcb-f638f1c66e5f

Never run `python3 update-sources.py` in full (non-`--append`) mode without
the user's explicit, in-the-moment confirmation — even as a workaround for
some `--append` limitation.

**Why:** A full run re-resolves and re-verifies *every* entry across all of
`sources.toml` (itch.io, Nexus, CurseForge, ModDB, every git repo, GitHub
releases, etc.) — large, network-heavy, side-effecting, and not scoped to
whatever you're actually trying to add. Did this once as a workaround for
`--append` skipping a `[cargo]` entry whose name collided with an existing
`[git]` source name in `previous_sources` — got a forceful correction:
"BAD AI! BAD AI! BAD AI! Running a full update would mean updating
everything in there, and I'm not ready to do that."

**How to apply:** If `--append` won't pick up a new/changed entry because
its name already exists in `sources.nix` (e.g. a `[cargo]` entry sharing a
name with its parent `[git]` source, by design, for `flatten()`
opaque-leaf/caching reasons — see `process_cargo` in `update-sources.py`),
the fix is to **delete just that entry's block from `sources.nix`** first,
then run `--append`. `--append` only reprocesses names missing from
`previous_sources`; everything else stays untouched and no network calls
happen for unrelated sources. This is the scoped, safe alternative to a
full run — confirmed working, user's own suggested fix. Always run
`update-sources.py` (append or otherwise) in the background
(\[[feedback_background_task_pattern]\]), and always sanity-check
`git diff sources.nix` before and after to confirm scope.
