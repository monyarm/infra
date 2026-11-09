{
  config,
  lib,
  fetchSteam,
  getFile,
  mkEcwolf,
  ...
}:
let
  WOLF3D = fetchSteam {
    appId = 2270;
    depotId = 2271;
    manifestId = 4340236882319013272;
    filelist = [ "regex:^base/[^/]+\\.WL6$" ];
    sha256 = "sha256-jWHeyzhnvU2ozvX6ySa+QIB8XGwxr58KlMJw9GYsN3k=";
  };
in
lib.mkIf config.games.ecwolf.enable {
  games.ecwolf.data = lib.genAttrs [
    "AUDIOHED.WL6"
    "AUDIOT.WL6"
    "GAMEMAPS.WL6"
    "MAPHEAD.WL6"
    "VGADICT.WL6"
    "VGAGRAPH.WL6"
    "VGAHEAD.WL6"
    "VSWAP.WL6"
  ] (f: WOLF3D |> getFile "base/${f}");

  programs.steam.games.WOLFENSTEIN_3D = mkEcwolf {
    name = "Wolfenstein 3D";
    data = "wl6";
    steamAppId = 2270;
    steamCdnImagesHash = "sha256-Nlo8Kwzabh5yWXr7ERih3GNMDsRWo19Bf61Uekeav78=";
  };
}
