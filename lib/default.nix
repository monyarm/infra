{
  pkgs,
  lib,
  system,
  mkOutOfStoreSymlink,
  ...
}:
let
  format = import ./format.nix { inherit pkgs lib; };
  constants = import ./constants.nix { inherit lib; };
  strings = import ./strings.nix ({ inherit pkgs lib; } // constants);
  imports = import ./imports.nix { inherit pkgs lib; };
  files = import ./files.nix { inherit pkgs lib mkOutOfStoreSymlink; };
  media = import ./media.nix { inherit pkgs lib; };
  meta = import ./meta.nix {
    inherit pkgs;
    inherit (pkgs) lib system;
  };
  fetchers = import ./fetchers.nix { inherit pkgs; };
in
{
  inherit
    format
    constants
    strings
    imports
    files
    media
    meta
    fetchers
    ;
}
// format
// constants
// strings
// imports
// files
// media
// meta
// fetchers
