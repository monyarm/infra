______________________________________________________________________

## name: feedback-commit-style description: "How to write and sign commits in the ~/.nix repo — succinct messages, no gpg signing when Claude commits." metadata: node_type: memory type: feedback originSessionId: 9ee05d2a-3a2d-4ac9-af8c-d2a4bb9d9774

In `~/.nix`, use `git commit --no-gpg-sign` when creating commits (repo has `commit.gpgsign=true` globally, but the user explicitly asked for unsigned commits from Claude). Keep commit messages succinct: a short single-line title (often a terse comma/and-joined list of what changed, e.g. "Add real Steam LaunchOptions via localconfig.vdf"); only add a body if it materially helps a future reader, capped at 1-2 plain sentences — never an itemized bullet list per change category.

**Why:** the user's own commit history (e.g. `259c1a3`, `e665787`, `2ff7056`) is terse — title-only or one short paragraph. Two prior Claude-authored commits (`adc950c`, `09aaa70`) used verbose multi-bullet essay-style bodies breaking from that norm, and the user called it out directly: "you've made the last couple much more verbose than my regular style."

**How to apply:** every time a commit is created in this repo (not just when explicitly reminded) — draft the subject line first and ask "would the user write three sentences of prose here, or one line?" before adding a body. Still include the `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>` trailer per standard practice; that's separate from body verbosity.
