{ lib, ... }:
let
  # KiB=1024^1, MiB=1024^2, GiB=1024^3, TiB=1024^4.
  prefixes = [
    "Ki"
    "Mi"
    "Gi"
    "Ti"
  ];
  pow1024 = exp: lib.foldl' (acc: _: acc * 1024) 1 (lib.range 1 exp);
in
{
  # Binary byte-size conversions -- e.g. `bytes.fromGiB 3` for a nix.conf
  # `min-free`/`max-free` value, which wants a raw byte count. Nested under
  # a static `bytes` key (not returned at this file's own top level) so
  # merging this file into lib/default.nix's `all` doesn't need `lib` forced
  # just to enumerate its keys -- see lib/constants.nix's `dirs` for the
  # same pattern.
  bytes = lib.listToAttrs (
    lib.imap1 (exp: prefix: {
      name = "from${prefix}B";
      value = n: n * pow1024 exp;
    }) prefixes
  );
}
