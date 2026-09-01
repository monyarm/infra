{
  config,
  lib,
  pkgs,
  fetchSteam,
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
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (mmxlcRoms) megaManX1 megaManX2 megaManX3;

    # regional variants, registered for enumeration only -- not launchable
    inherit (mmxlcRoms) rockManX1 rockManX2 rockManX3;
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

    MEGA_MAN_X_LEGACY_COLLECTION = {
      disabled = true;
      name = "Mega Man X Legacy Collection";
      steamAppId = 743890;
    };
  };
}
