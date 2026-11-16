{
  config,
  lib,
  fetchSteam,
  mkHalfLife,
  ...
}:
lib.mkIf config.games.halfLife.enable {
  games.halfLife.data.valve = fetchSteam {
    appId = 70;
    depotId = 1;
    manifestId = 2667117727132184734;
    os = "linux";
    filelist = [
      "regex:^valve/.*"
      "Text.tga"
      "Font.tga"
    ];
    sha256 = "sha256-62AoYSVIzjKBSOdHUfqFNzXml0Blt7PvDTbklrt+KLg=";
  };

  programs.steam.games.HALF_LIFE = mkHalfLife {
    name = "Half-Life";
    id = "valve";
    gamedir = "valve";
    gamelib = "hl";
    steamAppId = 70;
  };
}
