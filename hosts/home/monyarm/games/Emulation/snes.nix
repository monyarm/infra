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
  # X1-X3 only; X4 is a native reimplementation, not a real ROM
  MMXLC = fetchSteam {
    filelist = [ "RXC1.exe" ];
    appId = 743890;
    depotId = 743891;
    manifestId = 1036283505936301385;
    sha256 = "sha256-3NDrYRIYe8RMskKckX5GVvO1cwBwI59vMA+8mgvUwnY=";
  };

  mmxlcExtracted =
    pkgs.runCommand "mmxlc-extracted-roms"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        cp "${MMXLC}/RXC1.exe" $out/RXC1.exe
        cd $out
        ${pkgs.mmxlc-rom-extractor}/bin/mmxlc-rom-extractor
        rm RXC1.exe
      '';

  mmxlcRoms = lib.listToAttrs (
    lib.zipListsWith lib.nameValuePair
      [ "megaManX1" "megaManX2" "megaManX3" "rockManX1" "rockManX2" "rockManX3" ]
      (
        splitFiles [
          "Mega Man X.sfc"
          "Mega Man X2.sfc"
          "Mega Man X3.sfc"
          "Rock Man X.sfc"
          "Rock Man X2.sfc"
          "Rock Man X3.sfc"
        ] mmxlcExtracted
      )
  );

  inherit (config.games.emulation) marchive;
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (mmxlcRoms) megaManX1 megaManX2 megaManX3;

    # Contra Anniversary Collection's dumps have had Nintendo/Sega
    # copyright/branding screens stripped for legal reasons (contrapedia.wordpress.com);
    # unclear how that affects offset-based rom-hack IPS/BPS/UPS patches.
    contraIII = marchive.contra |> getFile "snes_ContraIII.smc";
    draculaX = marchive.castlevaniaAdvance |> getFile "CastlevaniaDraculaX_0409.SFC";
    # "_fake_rom" is MArchiveBatchTool's own naming, not dummy data -- valid
    # SNES header/size, just a different revision than the No-Intro dump.
    superCastlevaniaIv =
      marchive.castlevaniaAnniversary |> getFile "snes_01_supercastlevania4_fake_rom.smc";

    # regional variants, registered for enumeration only -- not launchable
    inherit (mmxlcRoms) rockManX1 rockManX2 rockManX3;
    superProbotector = marchive.contra |> getFile "snes_SuperProbotector.smc";
    contraSpiritsSufami = marchive.contra |> getFile "sufami_ContraSpirits.smc";
    draculaXAkumajou = marchive.castlevaniaAdvance |> getFile "AkumajouDraculaXX_0408.SFC";
    draculaXVampiresKiss = marchive.castlevaniaAdvance |> getFile "CastlevaniaVampiresKiss_0409.SFC";
    castlevania1Sufami = marchive.castlevaniaAnniversary |> getFile "sufami_01_AkumajouDracula.smc";
  };

  programs.steam.games = with config.games.emulation.roms; {
    MEGA_MAN_X1 = mkRom {
      name = "Mega Man X";
      rom = megaManX1;
      system = "snes";
    };
    MEGA_MAN_X2 = mkRom {
      name = "Mega Man X2";
      rom = megaManX2;
      system = "snes";
    };
    MEGA_MAN_X3 = mkRom {
      name = "Mega Man X3";
      rom = megaManX3;
      system = "snes";
    };

    CONTRA_III = mkRom {
      name = "Contra III: The Alien Wars";
      rom = contraIII;
      system = "snes";
    };
    DRACULA_X = mkRom {
      name = "Castlevania: Dracula X";
      rom = draculaX;
      system = "snes";
    };
    SUPER_CASTLEVANIA_IV = mkRom {
      name = "Super Castlevania IV";
      rom = superCastlevaniaIv;
      system = "snes";
    };

    MEGA_MAN_X_LEGACY_COLLECTION = {
      disabled = true;
      name = "Mega Man X Legacy Collection";
      steamAppId = 743890;
    };
  };
}
