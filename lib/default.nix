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
  constants = import ./constants.nix;
  helpers = import ./helpers.nix ({ inherit pkgs lib mkOutOfStoreSymlink; } // constants);
  meta = import ./meta.nix {
    inherit pkgs;
    inherit (pkgs) lib system;
  };
  fetchers = import ./fetchers.nix { inherit pkgs; };
  sops = import ./sops.nix { inherit config lib; };
in
{
  inherit
    format
    constants
    helpers
    meta
    fetchers
    sops # Inherit the sops attrset
    ;
}
