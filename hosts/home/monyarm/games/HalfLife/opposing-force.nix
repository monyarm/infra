{
  config,
  lib,
  fetchSteam,
  mkHalfLife,
  ...
}:
lib.mkIf config.games.halfLife.enable {
  games.halfLife.data.opfor = fetchSteam {
    appId = 50;
    depotId = 51;
    manifestId = 789184054796507140;
    os = "linux";
    filelist = [ "regex:^gearbox/.*" ];
    sha256 = "sha256-nn/cZERpBDqsRWUE8T9yj7tXuG2m+DYdaqbd/8tlrkA=";
  };

  programs.steam.games.HALF_LIFE_OPPOSING_FORCE = mkHalfLife {
    name = "Half-Life: Opposing Force";
    id = "opfor";
    gamedir = "gearbox";
    gamelib = "opfor";
    steamAppId = 50;
  };
}
