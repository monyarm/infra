{
  pkgs,
  lib,
  system,
  mkOutOfStoreSymlink,
  config,
  ...
}:
let
  format = import ./format.nix ({ inherit pkgs lib; } // strings);
  constants = import ./constants.nix { inherit lib; };
  strings = import ./strings.nix ({ inherit pkgs lib; } // constants);
  imp = import ./imports.nix { inherit pkgs lib; };
  files = import ./files.nix (
    {
      inherit
        pkgs
        lib
        mkOutOfStoreSymlink
        config
        ;
    }
    // strings
  );
  media = import ./media.nix ({ inherit pkgs lib; } // strings);
  meta = import ./meta.nix {
    inherit pkgs;
    inherit (pkgs) lib system;
  };
  fetchers = import ./fetchers.nix ({ inherit pkgs; } // constants // strings // imp);
  optimize = import ./optimize.nix (
    {
      inherit pkgs;
      inherit (pkgs) lib;
    }
    // files
    // imp
    // strings
    // format
    // misc
  );
  misc = import ./misc.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
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
      optimize
      misc
      ;
  }
  // format
  // constants
  // strings
  // imp
  // files
  // media
  // meta
  // fetchers
  // optimize
  // misc;
in
{
  customLib = all;
}
// all
