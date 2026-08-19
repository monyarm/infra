______________________________________________________________________

## name: feedback_verify_against_pinned_version description: "When designing against a dependency's API, fetch docs/source at the exact pinned commit/version in use, not the latest/master — APIs drift between them." metadata: node_type: memory type: feedback originSessionId: 2a85a860-258a-48c6-a6b9-bb36f603f849

Designed `hosts/home/monyarm/config/Claude/plugins.nix` against home-manager's
`programs.claude-code.plugins` option as documented on the `master` branch (fetched
via GitHub API with no `?ref=`) — an attrset-keyed API. The flake's actual pinned
home-manager commit was three weeks older and only had the plain `listOf` form;
eval failed with a confusing type error until re-fetching the option source at the
exact pinned rev (`?ref=<commit>`) showed the real, older shape.

**Why:** related to \[[feedback_verify_formats_before_implementing]\] but distinct —
that one is about researching external formats at all; this one is about *which*
version of a fast-moving dependency's docs/source to trust. Latest/master is not
what's actually running.

**How to apply:** before writing code against any nixpkgs/flake-input option or
API, check the flake's actual locked commit for that input (`flake.lock`) and fetch
source/docs at that exact ref, not the project's current default branch — especially
for young/actively-developed modules where the API is still moving.
