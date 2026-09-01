{
  lib,
  pkgs,
  compressRom,
  compressRom',
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
  inherit
    (
      (import ./mkRom.nix {
        inherit
          lib
          pkgs
          compressRom
          compressRom'
          ;
      })
    )
    mkRom
    ;

  marchiveUnpack =
    name: fetched:
    marchiveUnpack' name [] fetched;

  marchiveUnpack' =
    name: extraPaths: fetched:
    pkgs.runCommand "${name}-marchive-extracted"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        cp "$(find "${fetched}" -name alldata.bin)" "$(find "${fetched}" -name alldata.psb.m)" .
        chmod +w alldata.bin alldata.psb.m
        ${pkgs.marchive-batch-tool}/bin/MArchiveBatchTool fullunpack --keep alldata.psb.m zlib 25G/xpvTbsb+6 64
        mkdir -p $out
        cp -r alldata.psb.m_extracted/system/roms/. $out/
        ${lib.concatMapStringsSep "\n" (path: ''
          mkdir -p "$out/$(dirname ${path})"
          cp "alldata.psb.m_extracted/${path}" "$out/${path}"
        '') extraPaths}
      '';

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

    marchive = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = ''
        Registry of extracted alldata roms/ dirs, keyed by title, for
        MArchive-format (Konami/Capcom "alldata.bin") game collections.
      '';
    };
  };

  # mkRom.nix and marchive helpers are helpers, not modules
  imports = autoImport {
    path = ./.;
    exclude = [ "mkRom.nix" ];
  };

  config = {
    _module.args = {
      inherit mkRom marchiveUnpack;
      marchiveUnpack' = marchiveUnpack';
    };
  };
}
