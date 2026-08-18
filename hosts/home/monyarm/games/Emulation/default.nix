{
  lib,
  pkgs,
  compressRom,
  autoImport,
  ...
}:
# Owned but no known extractor -- multi-system Steam bundles, so noted here
# rather than split across single-system files:
#   Castlevania Dominus Collection (NDS, appId 2369900)
#   Mega Man Zero/ZX Legacy Collection (GBA+NDS, appId 999020)
#   Mega Man Legacy Collection 2 (SNES+PS1, appId 495050) -- PS1 entries
#     (MM9/10) reportedly native reimplementations, not emulated ROMs
#   Mega Man X Legacy Collection 2 (PS1, appId 743900)
let
  inherit ((import ./mkRom.nix { inherit lib pkgs compressRom; })) mkRom;
in
{
  options.games.emulation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = (builtins.getEnv "LIGHT") == "";
      description = "Whether to fetch/extract/compress/register emulated ROMs.";
    };

    roms = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = "Flat registry of registered ROM derivations, mirrors games.doom.wads.";
    };

    patches = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = "Flat registry of registered IPS/BPS/UPS patch derivations.";
    };
  };

  # mkRom.nix is a helper, not a module
  imports = autoImport {
    path = ./.;
    exclude = [ "mkRom.nix" ];
  };

  config = {
    _module.args = { inherit mkRom; };
  };
}
