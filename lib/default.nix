{
  pkgs,
  lib,
  system,
  mkOutOfStoreSymlink,
  config,
  ...
}:
let
  format = import ./format.nix { inherit pkgs lib; };
  constants = import ./constants.nix { inherit lib; };
  strings = import ./strings.nix ({ inherit pkgs lib; } // constants);
  imp = import ./imports.nix { inherit pkgs lib; };
  files = import ./files.nix {
    inherit
      pkgs
      lib
      mkOutOfStoreSymlink
      config
      ;
  };
  media = import ./media.nix { inherit pkgs lib; };
  meta = import ./meta.nix {
    inherit pkgs;
    inherit (pkgs) lib system;
  };
  fetchers = import ./fetchers.nix { inherit pkgs; };
  all = {
    inherit
      format
      constants
      strings
      imp
      files
      media
      meta
      fetchers
      ;
  }
  // format
  // constants
  // strings
  // imp
  // files
  // media
  // meta
  // fetchers;
in
{
  customLib = all;
}
// all
