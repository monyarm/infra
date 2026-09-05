{
  lib,
  pkgs,
  config,
  compressRom,
  addChecks,
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
      romPaths = [ "${romDir}" ] ++ extraRomPaths;
      checkedRomset = addChecks {
        smoke = ''
          testRomDir="$TMPDIR/${shortname}-rompath"
          mkdir -p "$testRomDir"
          ln -s ${lib.escapeShellArg (toString compressedRomset)} "$testRomDir/${shortname}.zip"
          HOME="$TMPDIR/mame-home"
          mkdir -p "$HOME"
          if ${pkgs.coreutils}/bin/timeout --foreground 10s ${pkgs.mame}/bin/mame \
            -rompath "$testRomDir:${lib.concatStringsSep ":" (map toString extraRomPaths)}" \
            -video none \
            -sound none \
            -bench 10 \
            ${lib.escapeShellArg shortname}; then
            report PASS smoke "MAME benchmark completed"
          else
            report FAIL smoke "MAME benchmark failed"
          fi
        '';
      } compressedRomset;
      romDir = pkgs.runCommand "${shortname}-romdir" { } ''
        mkdir -p $out
        ln -s ${checkedRomset} $out/${shortname}.zip
      '';
      rompath = lib.concatStringsSep ":" romPaths;
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
