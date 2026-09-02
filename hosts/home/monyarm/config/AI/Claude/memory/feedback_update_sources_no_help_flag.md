---
name: feedback-update-sources-no-help-flag
description: update-sources.py has no argparse/--help; any invocation without the literal string --append in argv runs a full update of every source in sources.toml
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 16dd47ec-4739-46a7-bab4-6ccc43f50f6a
---

`update-sources.py`'s CLI is just `append_mode = "--append" in sys.argv` (see `main()`,
~line 2301) — no `argparse`, no `--help`, no flag validation at all. Passing any other flag
(including `--help`) does NOT show usage and does NOT error; it silently runs with
`append_mode = False`, which skips the "already in previous_sources" guard entirely and
re-fetches/re-hashes **every single entry in every section of `sources.toml`** — caveman
binaries, mpv scripts, itch games, everything, unrelated to whatever you were actually trying
to update.

**Why:** caught before execution — I tried `update-sources.py --help` to check usage before a
real `--append` run and the user stopped me; running it would have kicked off a full-repo
source refresh instead of showing help.

**How to apply:** never invoke `update-sources.py` to "check what it does" or "see its flags."
Read the script's own `main()`/arg-handling directly (`grep -n "sys.argv" update-sources.py`)
instead of probing with `--help` or any other exploratory flag. The only two ways to run it
safely: exactly `python3 update-sources.py --append` (add newly-declared `sources.toml` entries
only, skip ones already resolved in `sources.nix`), or with zero args to intentionally refresh
literally everything (rarely what you want — confirm with the user first). See
[[project_packages_two_overlay_sites]] and [[feedback_prefer_sources_toml_fetchgittree]] for
the rest of this script's usage pattern.
