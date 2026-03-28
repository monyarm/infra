{ pkgs, ... }:
{
  anniversary30 = "${
    pkgs.fetchzip {
      url = "https://www.playstation.com/content/dam/global_pdc/en/corporate/files/wallpapers/30th-anniversary/30th-dark/PS30TH-Dark-Theme-Desktop-Wallpapers.zip";
      sha256 = "sha256-RTASfY/WjuPcRRhW3rhSjXxaL71N3zD49R2OsyHEpQY=";
      stripRoot = false;
    }
  }/S30TH_16x9_WALLPAPER.png";
}
