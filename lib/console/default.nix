# Entry point for console (PSP memory card) libraries and builders.
#
# `lib` covers the pure logic; `pkgs` / `buildPkgs` are only needed to construct
# derivations, so the pure validation helpers stay usable without a package set.
{
  lib,
  pkgs ? null,
  buildPkgs ? pkgs,
  fetchGameBrew ? null,
  psxpackager ? null,
  ...
}:

let
  paths = import ./paths.nix { inherit lib; };
  files = import ./files.nix { inherit lib paths; };
  # Registry entries are derivations, so they need the builder package set.
  plugins = import ./plugins.nix {
    pkgs = buildPkgs;
    inherit fetchGameBrew;
  };
  build = import ./build.nix {
    inherit lib;
    pkgs = buildPkgs;
  };
  # PS1 -> EBOOT.PBP converter. Needs the converter in the builder set.
  ps1eboot = import ./ps1eboot.nix {
    inherit lib;
    pkgs = buildPkgs;
    inherit psxpackager;
  };
in
{
  inherit
    paths
    files
    build
    plugins
    ps1eboot
    ;

  inherit (paths) validate isReserved;
  inherit (files) normalize;
  inherit (build) mkTree mkManifest;
  inherit (ps1eboot) mkPs1Eboot;
}
