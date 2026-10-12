# `config.psp.files` -> sorted, validated entry list for the builders.
# Recursive expansion happens at build time: reading a derivation directory at
# eval time would force the build (IFD), which this repo forbids.
{ lib, paths }:

let
  inherit (lib) filter mapAttrsToList sort;
in
{
  normalize =
    files:
    let
      entries = mapAttrsToList (path: entry: {
        inherit path;
        # Kept as the original value, NOT `toString`-ed: a string loses the
        # store context, so the builder would reference a path that is not a
        # dependency and the sandbox would not have it. Interpolating the
        # path/derivation value directly carries the context.
        source = entry.source or null;
        # Defaults keep normalize usable with partial entries in tests.
        enable = entry.enable or true;
        recursive = entry.recursive or false;
        owner = entry.owner or "";
      }) files;
      ordered = sort (a: b: a.path < b.path) (filter (e: e.enable) entries);
      dests = map (e: e.path) ordered;
      # deepSeq forces both guards so a violation throws at eval time.
      validated = map (e: paths.validate e.path) ordered;
      noCollisions = paths.assertNoAncestorConflicts dests;
    in
    builtins.deepSeq validated (builtins.deepSeq noCollisions ordered);
}
