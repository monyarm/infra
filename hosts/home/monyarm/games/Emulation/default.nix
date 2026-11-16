{
  lib,
  pkgs,
  compressRom,
  compressRom',
  addChecks,
  autoImport,
  mkSmoke,
  ...
}:
# Owned Steam collections with nothing to extract. All four are native ports
# reusing converted assets, not emulated cartridges. Multi-system bundles, so
# noted here rather than split across single-system files:
#   Castlevania Dominus (NDS, 2369900) -- one windata/alldata.bin MArchive
#     (key "Illegal function call", len 92); unpacks to per-file assets, no
#     .nds and no NTR-/TWL- header anywhere
#   Mega Man Zero/ZX LC (GBA+NDS, 999020) -- romPC holds only sound SE/BGM,
#     HD textures and UI and gallery; game data is per-stage .bin under
#     RZZC/{ZC,ZX,ZXA}/DATA in LZ77Wii chunk containers
#     (aluigi mega_man_zero_bin.bms), no cartridge header
#   Mega Man Legacy Collection 2 (SNES+PS1, 495050) -- disc is a ZipCrypto ZIP
#     of native rm07-rm10 asset trees, res00x/res01x are .womv movies
#   Mega Man X Legacy Collection 2 (PS1, 743900) -- X5-X8 native like X4 in
#     XLC1 (see snes/mmxlc.nix); only .arc/.sngw/.xsew/.webm assets
#
# TODO: Dungeons & Dragons: Chronicles of Mystara (arcade, 229480) is emulated,
# and its data/zip/{ddsom,ddtod}_essentials.wad.zip carry main.rom + gfx.rom.
# Program ROMs are recoverable: main.rom[:0x400000] in 0x80000 slices, 16-bit
# byte-swapped, is dd2e.03e..10 (ddsom) and dade.03c..07a (ddtod) by CRC.
# Blocked on gfx.rom being re-swizzled for the PC renderer, on QSound samples
# re-authored as .sb soundbanks, and on the 20-byte ddsom.key/ddtod.key that
# MAME needs to decrypt the program; it is not shipped with the depot.
# Revisit if the key is found in ManaGame.exe or someone cracks the gfx layout.
let
  inherit
    (
      (import ./mkRom.nix {
        inherit
          lib
          pkgs
          compressRom
          compressRom'
          addChecks
          mkSmoke
          ;
      })
    )
    mkRom
    ;

  marchiveUnpack = name: fetched: marchiveUnpack' name [ ] fetched;

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
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.package
          lib.types.path
        ]
      );
      default = { };
      description = "Flat registry of registered IPS/BPS/UPS patch files.";
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
    exclude = [
      "mkRom.nix"
      "emulators.nix"
    ];
  };

  config = {
    _module.args = {
      inherit mkRom marchiveUnpack;
      inherit marchiveUnpack';
    };
  };
}
