{
  config,
  lib,
  pkgs,
  getFile,
  mkRom,
  ...
}:
let
  inherit (config.games.emulation) marchive;

  # Pre-filled SRAM: English translation uses more data than fits in NES ROM,
  # so extra data lives in SRAM. Emulator must load this as initial SRAM content.
  kidDraculaSav =
    pkgs.runCommand "kid-dracula.sav"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        awk '/m_sram_data = \[/{flag=1; next} /\];/{if(flag) exit} flag' \
          "${marchive.castlevaniaAnniversary}/073/script/title_standalone.nut" \
          | grep -o '0x[0-9a-fA-F][0-9a-fA-F]' | cut -c3-4 | tr -d '\n' \
          | ${pkgs.python3}/bin/python3 -c 'import sys, binascii; sys.stdout.buffer.write(binascii.unhexlify(sys.stdin.read()))' \
          > $out
      '';
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    castlevania1 = marchive.castlevaniaAnniversary |> getFile "nes_01_Castlevania.nes";
    castlevania2 = marchive.castlevaniaAnniversary |> getFile "nes_02_Castlevania2.nes";
    castlevania3 = marchive.castlevaniaAnniversary |> getFile "nes_02_Castlevania3.nes";
    kidDracula = marchive.castlevaniaAnniversary |> getFile "kid-dracula.nes";

    # regional variants, registered for enumeration only -- not launchable
    castlevania1Famicom = marchive.castlevaniaAnniversary |> getFile "famicom_01_AkumajouDracula.nes";
    castlevania3Famicom = marchive.castlevaniaAnniversary |> getFile "famicom_03_AkumajouDensetsu.nes";
    kidDraculaFamicom = marchive.castlevaniaAnniversary |> getFile "famicom_04_BokuDraculakun.nes";
  };

  programs.steam.games = with config.games.emulation.roms; {
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
      sidecar = kidDraculaSav;
      system = "nes";
    };
  };
}
