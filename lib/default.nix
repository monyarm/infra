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
  helpers = import ./helpers.nix ({ inherit pkgs lib mkOutOfStoreSymlink; } // constants);
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
    helpers
    meta
    fetchers
    ;
}
