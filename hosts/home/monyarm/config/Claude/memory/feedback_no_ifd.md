______________________________________________________________________

## name: feedback_no_ifd description: "Don't use builtins.readFile/similar on a derivation's output path at eval time (IFD) — move the check into the build itself." metadata: node_type: memory type: feedback originSessionId: 2a85a860-258a-48c6-a6b9-bb36f603f849

`builtins.readFile "${someFetchedSrc}/some/file"` where `someFetchedSrc` is a
derivation forces Nix to realize that derivation *during evaluation* before the
expression can finish evaluating — that's Import From Derivation. Caught mid-session
when I added a cross-check comparing a fetched repo's version-marker file against a
separately-pinned value, using `builtins.readFile` at the top of a package's `let`
block.

**Why:** IFD only silently works because `--impure` was already in use this session;
it's real added eval-time cost (forces a full fetch/build before the rest of the
expression evaluates) and doesn't fit this repo's otherwise IFD-free eval model
(see `lib/optimize/dynamic.nix`'s header on why that file goes to real lengths to
avoid it).

**How to apply:** If a check needs a fetched source's file content, do the
comparison in a build step (`buildPhase`/`preBuild` shell script) against a
plain Nix *string* value already known at eval time (e.g. from `sources.nix`),
not via `builtins.readFile` on a derivation path. The source is unpacked into the
build tree by then regardless — no extra realization needed.
