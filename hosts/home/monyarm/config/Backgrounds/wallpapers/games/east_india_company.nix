{ fetchSteam, splitFiles, ... }:
{
  eastIndiaCompany =
    let
      files = [
        "Wallpapers/1920x1080/EIC_wallpaper04_1920.jpg"
        "Wallpapers/1920x1080/EIC_wallpaper01_1920.jpg"
        "Wallpapers/1920x1080/EIC_wallpaper02_1920.jpg"
        "Wallpapers/1920x1080/EIC_wallpaper03_1920.jpg"
        "Wallpapers/1920x1080/EIC_wallpaper06_1920.jpg"
        "Wallpapers/1920x1080/EIC_wallpaper05_1920.jpg"
        "Wallpapers/1920x1080/EIC_wallpaper07_1920.jpg"
      ];
    in
    fetchSteam {
      appId = 254000;
      depotId = 254001;
      manifestId = 5884013578995757201;
      sha256 = "sha256-mRDIs1P5dknrLQx9HTTkvH/mT+MLldrpB92d/J/BUbA=";
      filelist = files;
    }
    |> splitFiles files;
}
