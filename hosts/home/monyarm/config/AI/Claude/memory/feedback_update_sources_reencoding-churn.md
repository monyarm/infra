______________________________________________________________________

## name: update-sources-reencoding-churn description: Any update-sources.py run re-encodes every entry in sources.nix (41.6MB -> 27.3MB) with zero semantic change, so the diff is never small. metadata: node_type: memory type: feedback originSessionId: dd2c7cec-fbaa-4c55-bdcb-f638f1c66e5f

**Every** run — `--append` or a scoped selector run — rewrites all 289 entries in
`sources.nix`, not just the ones you selected. Expect a ~1.6M-line diff.

**Why:** `load_previous_nix` reads the file with `nix eval --json`, which evaluates the
compact encodings away (`flattenPaths` trees, `expandPool`, `expandClusters` become plain
lists/records). The post-processing pass then re-compacts them via `render_path_list`, but
re-derives a *different, tighter* encoding than the one committed. Verified 2026-10-13:
output is 27.3MB / 825,616 lines vs the committed 41.6MB / 1,036,210 lines, while
`nix eval --json` of both hashes identically
(`3ef425128d0a48a65887c8eac6d4e256710b5314c8628f42fdcda0da20220625`). So the data is
identical; only the encoding changed.

**How to apply:** do NOT read a huge `git diff sources.nix` as "the update went wrong," and do
not assume a scoped run is a small diff. To verify a scoped run changed the right thing,
compare semantics, not text — e.g. `nix eval --json -f <file> <dotted.key>` before and after,
or compare whole-file `nix eval --json | sha256sum`. A byte-stable carry-over (keep
unselected entries as text instead of round-tripping them through `nix eval --json`) would fix
this properly; not done yet. Also see [[feedback_update_sources_full_run_danger]].