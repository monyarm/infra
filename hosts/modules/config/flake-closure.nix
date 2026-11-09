{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # same wrapper as the flake's `formatter`, built from this system's pkgs:
  # inputs.self.formatter would force the flake's own perSystem nixpkgs
  formatter = (inputs.treefmt-nix.lib.evalModule pkgs ../../../treefmt.nix).config.build.wrapper;
in
{
  # keep repo tooling past GC: `nix fmt`, our flake input sources.
  # direnv shell: nix-direnv roots it already (.direnv/).
  system.extraDependencies = [
    formatter
  ]
  ++ lib.mapAttrsToList (_: i: i.outPath) (removeAttrs inputs [ "self" ]);
}
