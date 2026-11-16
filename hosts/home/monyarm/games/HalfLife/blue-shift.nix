{
  config,
  lib,
  fetchSteam,
  mkHalfLife,
  ...
}:
lib.mkIf config.games.halfLife.enable {
  games.halfLife.data.bshift = fetchSteam {
    appId = 130;
    depotId = 130;
    manifestId = 2832280714065945284;
    os = "linux";
    filelist = [ "regex:^bshift/.*" ];
    sha256 = "sha256-Tj/gcwPiE62sP0kHZETX9VTyQByFQ6dQYAj0pDIvyiI=";
  };

  programs.steam.games.HALF_LIFE_BLUE_SHIFT = mkHalfLife {
    name = "Half-Life: Blue Shift";
    id = "bshift";
    gamedir = "bshift";
    gamelib = "bshift";
    steamAppId = 130;
  };
}
