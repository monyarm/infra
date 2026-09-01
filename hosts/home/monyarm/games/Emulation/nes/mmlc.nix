{
  config,
  lib,
  pkgs,
  fetchSteam,
  getFile,
  splitFiles,
  mkRom,
  patchFile,
  fetchGitTree,
  sources,
  ...
}:
let
  # roms baked as byte ranges inside Proteus.exe; mmlc-dac-extractor pulls them out
  MMLC = fetchSteam {
    filelist = [ "Proteus.exe" ];
    appId = 363440;
    depotId = 363441;
    manifestId = 1471104847962813070;
    sha256 = "sha256-S5FegdOGa6ugR2LJ0awdeO9Tii1Itg19k1jvg2MRjWQ=";
  };

  mmlcExtracted =
    pkgs.runCommand "mmlc-extracted-roms"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        cp "${MMLC}/Proteus.exe" $out/Proteus.exe
        cd $out
        ${pkgs.mmlc-dac-extractor}/bin/mmlc-extractor
        rm Proteus.exe
      '';

  # extractor's own naming: game 1 has space before paren, 2-6 don't
  mmlcRomName =
    n:
    if n == 1 then
      "Mega Man (Mega Man Legacy Collection).nes"
    else
      "Mega Man ${toString n}(Mega Man Legacy Collection).nes";

  mmlcRoms = lib.listToAttrs (
    lib.zipListsWith lib.nameValuePair
      [ "megaMan1" "megaMan2" "megaMan3" "megaMan4" "megaMan5" "megaMan6" ]
      (
        splitFiles (map mmlcRomName [
          1
          2
          3
          4
          5
          6
        ]) mmlcExtracted
      )
  );

  mmlcSource = fetchGitTree sources.tools.mmlcDacExtractor;

  mmlcPatches = {
    megaMan1Restore = getFile "patches/mmlc/Mega Man (Original).ips" mmlcSource;
    megaMan2Restore = getFile "patches/mmlc/Mega Man 2 (Original).ips" mmlcSource;
    megaMan3Restore = getFile "patches/mmlc/Mega Man 3 (Original).ips" mmlcSource;
    megaMan4Restore = getFile "patches/mmlc/Mega Man 4 (Original).ips" mmlcSource;
    megaMan5Restore = getFile "patches/mmlc/Mega Man 5 (Original).ips" mmlcSource;
    megaMan6Restore = getFile "patches/mmlc/Mega Man 6 (Original).ips" mmlcSource;
  };

  patchedMmlcRoms = {
    megaMan1 = mmlcRoms.megaMan1 |> patchFile mmlcPatches.megaMan1Restore;
    megaMan2 = mmlcRoms.megaMan2 |> patchFile mmlcPatches.megaMan2Restore;
    megaMan3 = mmlcRoms.megaMan3 |> patchFile mmlcPatches.megaMan3Restore;
    megaMan4 = mmlcRoms.megaMan4 |> patchFile mmlcPatches.megaMan4Restore;
    megaMan5 = mmlcRoms.megaMan5 |> patchFile mmlcPatches.megaMan5Restore;
    megaMan6 = mmlcRoms.megaMan6 |> patchFile mmlcPatches.megaMan6Restore;
  };
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (patchedMmlcRoms)
      megaMan1
      megaMan2
      megaMan3
      megaMan4
      megaMan5
      megaMan6
      ;
  };

  games.emulation.patches = {
    inherit (mmlcPatches)
      megaMan1Restore
      megaMan2Restore
      megaMan3Restore
      megaMan4Restore
      megaMan5Restore
      megaMan6Restore
      ;
  };

  programs.steam.games = with config.games.emulation.roms; {
    MEGA_MAN_1 = mkRom {
      name = "Mega Man";
      rom = megaMan1;
      system = "nes";
    };
    MEGA_MAN_2 = mkRom {
      name = "Mega Man 2";
      rom = megaMan2;
      system = "nes";
    };
    MEGA_MAN_3 = mkRom {
      name = "Mega Man 3";
      rom = megaMan3;
      system = "nes";
    };
    MEGA_MAN_4 = mkRom {
      name = "Mega Man 4";
      rom = megaMan4;
      system = "nes";
    };
    MEGA_MAN_5 = mkRom {
      name = "Mega Man 5";
      rom = megaMan5;
      system = "nes";
    };
    MEGA_MAN_6 = mkRom {
      name = "Mega Man 6";
      rom = megaMan6;
      system = "nes";
    };

    MEGA_MAN_LEGACY_COLLECTION = {
      disabled = true;
      name = "Mega Man Legacy Collection";
      steamAppId = 363440;
    };
  };
}
