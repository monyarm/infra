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

**How to apply:** Prefer a **scoped selector run**, which re-fetches one entry and carries
everything else over — `./update-sources.py tools.wadptr` for a single entry, or
`--section romrinth` style (`--section <name>`) for a whole fetcher kind. That replaced the
old workaround of deleting the entry's block from `sources.nix` before `--append`, which is no
longer needed. If a scoped run won't work, `--append` still only picks up TOML entries missing
from `previous_sources`. A zero-arg run is the only thing that touches everything — always
confirm that with the user first. Run `update-sources.py` in the background
(\[[feedback_background_task_pattern]\]), and always sanity-check `git diff sources.nix` before
and after — remember that diff is large even for a scoped run, since every run re-encodes all
entries (expected, documented in AGENTS.md; verify by semantics, not by diff size).
