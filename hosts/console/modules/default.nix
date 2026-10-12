# Base module for every console platform. Collects platform module imports and
# the shared `assertions` option that other console modules contribute to.
{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  imports = [
    ./files.nix
    ./resources.nix
    ./categories-lite.nix
    ./plugins.nix
    ./ark5.nix
  ];

  options.assertions = mkOption {
    type = types.listOf types.unspecified;
    default = [ ];
    internal = true;
    description = "Assertions contributed by console modules.";
  };
}
