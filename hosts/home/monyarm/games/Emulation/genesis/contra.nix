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
    contraHardCorps = marchive.contra |> getFile "sega_ContraHardCorps.bin";

    # regional variants, registered for enumeration only -- not launchable
    contraTheHardCoreJp = marchive.contra |> getFile "sega_ContraTheHardCore.BIN";
    probotectorGenesis = marchive.contra |> getFile "sega_Probotector.BIN";
    probotectorGenesisHackedWW = marchive.contra |> getFile "sega_Probotector_hacked_WW.BIN";
  };

  programs.steam.games = with config.games.emulation.roms; {
    CONTRA_HARD_CORPS = mkRom {
      name = "Contra: Hard Corps";
      rom = contraHardCorps;
      system = "genesis";
    };
  };
}
