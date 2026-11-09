{
  config,
  lib,
  fetchSteam,
  mkRaze,
  ...
}:
lib.mkIf config.games.raze.enable {
  # WT loads E5 maps/sound/music/CONs loose from beside the GRP; skip UI/videos/textures
  games.raze.grps.duke3dWorldTour = fetchSteam {
    appId = 434050;
    depotId = 434051;
    manifestId = 5242689339511472707;
    filelist = [ "regex:^([^/]+\\.(GRP|CON|RTS|ART)|(maps|sound|music)/.*)$" ];
    sha256 = "sha256-0Fno/lvV+Ax9XUYvJ18H4uI0gc+vmUMbwhMlcSJZvdE=";
  };

  programs.steam.games.DUKE3D_WORLD_TOUR = mkRaze {
    name = "Duke Nukem 3D: 20th Anniversary World Tour";
    grp = config.games.raze.grps.duke3dWorldTour;
    file = "DUKE3D.GRP";
    steamAppId = 434050;
    steamCdnImagesHash = "sha256-r5OSDpMx3QBR0cygs4iOvy9vvtoCivQCvM0nNM/MoLg=";
  };
}
