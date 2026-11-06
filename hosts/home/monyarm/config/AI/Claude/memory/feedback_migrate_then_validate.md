---
name: feedback_migrate_then_validate
description: "For major-version config migrations, read the new version's migration docs first; don't validate the old config before migrating"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 28b4d7e1-1427-49cd-bda8-2e85c0e57265
  modified: 2026-11-05T07:29:51.645Z
---

For a major-version config migration (e.g. opencode 1 to 2), read the new version's migration notes/changelog first. Then rewrite the config. Validate only the migrated result.

**Why:** I once started by schema-validating our current opencode settings before doing any migration. The user called that dumb: the old config is expected to be wrong for the new version, so validating it first just wastes a step.

**How to apply:** Run docs, then the rewrite, then validation. When migration semantics are unclear, ask the user instead of guessing. See [[feedback_verify_against_pinned_version]].
