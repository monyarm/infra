{
  config,
  lib,
  fetchSteam,
  getFile,
  mkEcwolf,
  ...
}:
let
  # The Steam Wolfenstein 3D app also ships Spear of Destiny under base/m1.
  SPEAR = fetchSteam {
    appId = 2270;
    depotId = 2271;
    manifestId = 4340236882319013272;
    filelist = [ "regex:^base/m1/.*\\.SOD$" ];
    sha256 = "sha256-/SD1RTMR7rkc2MF7u9fXYAHW1JrPr7vEqaBaG3WwUjc=";
  };
in
lib.mkIf config.games.ecwolf.enable {
  games.ecwolf.data = lib.genAttrs [
    "AUDIOHED.SOD"
    "AUDIOT.SOD"
    "GAMEMAPS.SOD"
    "MAPHEAD.SOD"
    "VGADICT.SOD"
    "VGAGRAPH.SOD"
    "VGAHEAD.SOD"
    "VSWAP.SOD"
  ] (f: SPEAR |> getFile "base/m1/${f}");

  # No steamAppId: the 2270 store entry is already replaced by Wolfenstein 3D.
  programs.steam.games.WOLFENSTEIN_SPEAR_OF_DESTINY = mkEcwolf {
    name = "Wolfenstein: Spear of Destiny";
    data = "sod";
  };
}
