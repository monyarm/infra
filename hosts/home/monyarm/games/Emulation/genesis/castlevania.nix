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
    castlevaniaBloodlines =
      marchive.castlevaniaAnniversary |> getFile "sega_us_CastlevaniaBloodlines.bin";

    # regional variants, registered for enumeration only -- not launchable
    vampireKillerJp = marchive.castlevaniaAnniversary |> getFile "sega_jp_VampireKiller.bin";
  };

  programs.steam.games = with config.games.emulation.roms; {
    CASTLEVANIA_BLOODLINES = mkRom {
      name = "Castlevania: Bloodlines";
      rom = castlevaniaBloodlines;
      system = "genesis";
    };
  };
}
