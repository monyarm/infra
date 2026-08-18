{
  lib,
  pkgs,
  config,
  compressRom,
  autoImport,
  ...
}:
let
  # stages the recompressed romset zip into its own rompath dir under the
  # shortname MAME expects
  mkArcade =
    {
      romset,
      shortname,
      extraRomPaths ? [ ],
      ...
    }@args:
    let
      compressedRomset = compressRom romset;
      romDir = pkgs.runCommand "${shortname}-romdir" { } ''
        mkdir -p $out
        ln -s ${compressedRomset} $out/${shortname}.zip
      '';
      rompath = lib.concatStringsSep ":" ([ "${romDir}" ] ++ extraRomPaths);
    in
    (lib.removeAttrs args [
      "romset"
      "shortname"
      "extraRomPaths"
    ])
    // {
      game = shortname;
      launcher = {
        package = pkgs.mame;
        args = [
          "-rompath"
          rompath
        ];
      };
    };

  # every NeoGeo MVS title needs the shared neogeo.zip BIOS on its rompath
  mkNeoGeo =
    args:
    mkArcade (
      args
      // {
        extraRomPaths =
          (args.extraRomPaths or [ ])
          ++ (lib.optional (
            config.games.emulation.arcade.neogeoBios != null
          ) "${config.games.emulation.arcade.neogeoBios}");
      }
    );
in
{
  options.games.emulation.arcade.neogeoBios = lib.mkOption {
    type = lib.types.nullOr lib.types.package;
    default = null;
    description = "Extracted neogeo.zip BIOS dir, populated by arcade/neogeo.nix.";
  };

  imports = autoImport ./.;

  config = {
    _module.args = { inherit mkArcade mkNeoGeo; };
  };
}
