{
  config,
  lib,
  fetchSteam,
  getFile,
  rename,
  mkRom,
  ...
}:
let
  noahsArkDl = fetchSteam {
    filelist = [ "res/game" ];
    appId = 1539100;
    depotId = 1539101;
    manifestId = 3930250710537691245;
    sha256 = "sha256-vAduN+Pn6u6TxKEHAvh+0s2fxt0rBflwOiHvg3cUID8=";
  };
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms.noahsArk = noahsArkDl |> getFile "res/game" |> rename "game.nes";

  programs.steam.games = with config.games.emulation.roms; {
    NOAHS_ARK = mkRom {
      name = "Noah's Ark";
      rom = noahsArk;
      system = "nes";
      steamAppId = 1539100;
      steamCdnImagesHash = "sha256-77fQeCArDdb4vOw/Y6yaaF+W7A0gK7ZJ8ujutURsdxg=";
    };
  };
}
