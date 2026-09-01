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
    # Contra Anniversary Collection's dumps have had Nintendo/Sega
    # copyright/branding screens stripped for legal reasons (contrapedia.wordpress.com);
    # unclear how that affects offset-based rom-hack IPS/BPS/UPS patches.
    contraIII = marchive.contra |> getFile "snes_ContraIII.smc";

    # regional variants, registered for enumeration only -- not launchable
    superProbotector = marchive.contra |> getFile "snes_SuperProbotector.smc";
    contraSpiritsSufami = marchive.contra |> getFile "sufami_ContraSpirits.smc";
  };

  programs.steam.games = with config.games.emulation.roms; {
    CONTRA_III = mkRom {
      name = "Contra III: The Alien Wars";
      rom = contraIII;
      system = "snes";
    };
  };
}
