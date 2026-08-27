# fonttools subset environment for lib/optimize/handlers/font.nix -- a
# proper package (not a handler-local let) so the dynamic-optimize inner
# sandbox can overlay it as a prebuilt store path like any other tool,
# instead of constructing python3.withPackages in there.
{ pkgs, ... }:

pkgs.python3.withPackages (ps: [ ps.fonttools ])
