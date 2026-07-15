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
  strings = import ./strings.nix ({ inherit pkgs lib; } // constants // misc);
  imp = import ./imports.nix ({ inherit pkgs lib; } // misc);
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
    // misc
  );
  media = import ./media.nix ({ inherit pkgs lib; } // strings // misc);
  meta = import ./meta.nix {
    inherit pkgs;
    inherit (pkgs) lib system;
  };
  fetchers = import ./fetchers.nix ({ inherit pkgs; } // constants // strings // imp // files);
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
