{
  config,
  lib,
  getFile,
  mkRom,
  ...
}:
let
  inherit (config.games.emulation) marchive;
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    draculaX = marchive.castlevaniaAdvance |> getFile "CastlevaniaDraculaX_0409.SFC";
    # "_fake_rom" is MArchiveBatchTool's own naming, not dummy data -- valid
    # SNES header/size, just a different revision than the No-Intro dump.
    superCastlevaniaIv =
      marchive.castlevaniaAnniversary |> getFile "snes_01_supercastlevania4_fake_rom.smc";

    # regional variants, registered for enumeration only -- not launchable
    draculaXAkumajou = marchive.castlevaniaAdvance |> getFile "AkumajouDraculaXX_0408.SFC";
    draculaXVampiresKiss = marchive.castlevaniaAdvance |> getFile "CastlevaniaVampiresKiss_0409.SFC";
    castlevania1Sufami = marchive.castlevaniaAnniversary |> getFile "sufami_01_AkumajouDracula.smc";
  };

  programs.steam.games = with config.games.emulation.roms; {
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
  };
}
