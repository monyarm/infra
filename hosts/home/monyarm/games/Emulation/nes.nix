{
  config,
  lib,
  pkgs,
  fetchSteam,
  getFile,
  splitFiles,
  mkRom,
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

  inherit (config.games.emulation) marchive;
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (mmlcRoms)
      megaMan1
      megaMan2
      megaMan3
      megaMan4
      megaMan5
      megaMan6
      ;

    contra = marchive.contra |> getFile "nes_Contra.nes";
    superC = marchive.contra |> getFile "nes_SuperC.nes";

    castlevania1 = marchive.castlevaniaAnniversary |> getFile "nes_01_Castlevania.nes";
    castlevania2 = marchive.castlevaniaAnniversary |> getFile "nes_02_Castlevania2.nes";
    castlevania3 = marchive.castlevaniaAnniversary |> getFile "nes_02_Castlevania3.nes";
    # SRAM save data for this rom recovered separately by marchive.nix's
    # kidDraculaSavExtra (kid-dracula.sav, not a rom, not registered here).
    kidDracula = marchive.castlevaniaAnniversary |> getFile "kid-dracula.nes";

    # regional variants, registered for enumeration only -- not launchable
    probotectorII = marchive.contra |> getFile "nes_ProbotectorII.nes";
    contraFamicom = marchive.contra |> getFile "famicom_Contra.nes";
    superContraFamicom = marchive.contra |> getFile "famicom_SuperContra.nes";
    castlevania1Famicom = marchive.castlevaniaAnniversary |> getFile "famicom_01_AkumajouDracula.nes";
    castlevania3Famicom = marchive.castlevaniaAnniversary |> getFile "famicom_03_AkumajouDensetsu.nes";
    kidDraculaFamicom = marchive.castlevaniaAnniversary |> getFile "famicom_04_BokuDraculakun.nes";
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

    CONTRA = mkRom {
      name = "Contra";
      rom = contra;
      system = "nes";
    };
    SUPER_C = mkRom {
      name = "Super C";
      rom = superC;
      system = "nes";
    };

    CASTLEVANIA = mkRom {
      name = "Castlevania";
      rom = castlevania1;
      system = "nes";
    };
    CASTLEVANIA_2 = mkRom {
      name = "Castlevania II: Simon's Quest";
      rom = castlevania2;
      system = "nes";
    };
    CASTLEVANIA_3 = mkRom {
      name = "Castlevania III: Dracula's Curse";
      rom = castlevania3;
      system = "nes";
    };
    KID_DRACULA = mkRom {
      name = "Kid Dracula";
      rom = kidDracula;
      system = "nes";
    };
  };
}
