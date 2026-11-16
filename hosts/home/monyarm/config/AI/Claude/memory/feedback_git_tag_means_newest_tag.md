---
name: feedback-git-tag-means-newest-tag
description: In sources TOML, [git-tag] tracks the newest tag automatically, so a "#vX.Y" URL fragment is dead syntax; pick git-tag only when the newest tag is recent, else use [git] for master
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-13T18:26:17.175Z
---

`[git-tag]` entries in the sources TOML mean "track the newest tag", so do not append a specific tag to the URL (`https://…/repo#trx-1.12` is dead syntax — `process_git_tag` calls `parse_git_url` and discards the `#tag`, then picks `max(tags, semver_sort_key)`). Just give the repo URL.

Choice between `[git-tag]` and `[git]`: check how stale the newest tag is. If it is recent relative to the project's release cadence, use `[git-tag]` with the repo URL; if it is clearly behind, use `[git]` so the build tracks master.

**Why:** User stated plainly that pinning a tag "is not what git-tag is for"; the point of the fetcher is to follow upstream releases, and the tag-vs-master choice is a judgement about currency, not a hardcoded pin.

**How to apply:** Before writing an engine/tool source entry, fetch the latest tag date and the commit count since it (`git ls-remote --tags`, then a shallow log of master). Recent → `[git-tag] <url>`. Stale → `[git] <url>`. Example: TRX `trx-1.12` was 2026-11-02, ~11 days / 41 commits behind on 2026-11-13 with a 2–6 week cadence, so `[git-tag] https://github.com/LostArtefacts/TRX` was correct.
