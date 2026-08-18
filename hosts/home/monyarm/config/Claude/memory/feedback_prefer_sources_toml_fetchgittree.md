______________________________________________________________________

## name: feedback-prefer-sources-toml-fetchgittree description: "For new GitHub-hosted tool/source packages, add an entry to sources.toml + run update-sources.py --append, and consume it via fetchGitTree — not a literal fetchFromGitHub with a hand-copied rev/hash." metadata: node_type: memory type: feedback originSessionId: b2bdba37-c049-4eae-84c8-5a53dba34006

For any new package whose source is a git repo (GitHub or otherwise), prefer the existing
`sources.toml` → `update-sources.py --append` → `sources.nix` → `fetchGitTree sources.tools.<name>`
pipeline (as `packages/wadptr.nix`/`packages/scummvm-tools.nix` already do) over writing a
literal `fetchFromGitHub { owner; repo; rev; hash; }` by hand inside the package file.

**Why:** This is the repo's established, already-automated convention for tracking/updating
git-based tool sources — it keeps every git source's rev/hash centralized and machine-updatable
in one place (`sources.nix`) instead of scattered across individual package files, and
`update-sources.py --append` (not a full rerun) only fetches newly-added `sources.toml` entries,
leaving existing ones untouched.

**How to apply:** `sources.toml` line: `tools.<camelCaseName> = "https://github.com/<owner>/<repo>"`
(optionally `#<rev>` suffix to pin an exact commit for a no-tags repo). Then run
`./update-sources.py --append` (real network-fetching command — see
\[[feedback_no_tail_short_logs]\] for why not to probe this script's CLI with a guessed `--help`
flag first). Package file takes `sources` + `fetchGitTree` as args and does
`src = fetchGitTree sources.tools.<camelCaseName>;`, matching `packages/wadptr.nix`. Only fall
back to `fetchurl`/`fetchzip` directly in the package file for things that are NOT a git
checkout — a prebuilt GitHub Releases binary asset, a raw gist file, etc. — since
`update-sources.py`'s `git` section fetches the repo tree, not release assets.

**Version string:** use the bare date directly — `version = sources.tools.<name>.date;` — not
`"0-unstable-${sources.tools.<name>.date}"`. The `0-unstable-${date}` form in `wadptr.nix` is not
the convention to copy; `mcp-compressor.nix`/`caveman-cli.nix` show a related but distinct
`.tag or "0-unstable-${date}"` fallback for sources that track a release tag — not applicable when
the source has no `tag` field. See also \[[feedback_packages_need_ellipsis_arg]\].
