---
name: feedback-update-sources-no-help-flag
description: update-sources.py now has real argparse parsing (--help/--append/--section/SELECTOR); unknown args exit 2 instead of silently triggering a full refresh
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 16dd47ec-4739-46a7-bab4-6ccc43f50f6a
---

`update-sources.py` used to parse args with a single `append_mode = "--append" in sys.argv`,
so every other flag — `--help` included — was silently ignored and ran a **full** refresh of
every source. That landmine is now closed: the CLI is real `argparse` (`parse_args()`), so
`--help` prints usage (exit 0) and an unknown flag exits 2.

Safe invocations:

| command | effect |
|---|---|
| `./update-sources.py redump` | re-fetch every `redump.*` entry, carry the rest over |
| `./update-sources.py redump.psp` | re-fetch exactly that entry |
| `./update-sources.py --section romhacking` | re-fetch every entry in that TOML section (repeatable) |
| `./update-sources.py --append` | add only TOML entries missing from `sources.nix` |
| `./update-sources.py` (no args) | full refresh of everything — confirm with the user first |

Selectors are dotted-prefix matched on the source key, so `redump` cannot hit `redump2.foo`.
Passing a selector implies preserve mode (everything else is carried over). A selector that
matches nothing exits 1 and lists the available namespaces and sections rather than
rewriting `sources.nix` for nothing.

**Still true:** every run re-encodes all 289 entries, so `git diff sources.nix` is never small
— that is expected and documented in AGENTS.md, not a symptom of a bad run. Verify by
comparing semantics (`nix eval --json -f sources.nix | sha256sum`), not by diff size.

See [[feedback_update_sources_full_run_danger]] and
[[feedback_prefer_sources_toml_fetchgittree]] for the rest of this script's usage pattern.