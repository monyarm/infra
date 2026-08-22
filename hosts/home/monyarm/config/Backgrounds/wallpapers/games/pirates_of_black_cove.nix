{ fetchSteam, splitFiles, ... }:
{
  piratesOfBlackCove =
    let
      files = [
        "wallpapers/1920x1080/PoBC_07_1920x1080.PNG"
        "wallpapers/1920x1080/PoBC_03_1920x1080.PNG"
        "wallpapers/1920x1080/PoBC_06_1920x1080.PNG"
        "wallpapers/1920x1080/PoBC_05_1920x1080.PNG"
        "wallpapers/1920x1080/PoBC_02_1920x1080.PNG"
        "wallpapers/1920x1080/PoBC_01_1920x1080.PNG"
        "wallpapers/1920x1080/PoBC_08_1920x1080.PNG"
        "wallpapers/1920x1080/PoBC_04_1920x1080.PNG"
      ];
    in
    fetchSteam {
      appId = 254040;
      depotId = 254041;
      manifestId = 7328962440490802470;
      sha256 = "sha256-QbBkvV/V6qOXn1d+z+1hOx7A6ELVs4/64bspGZhi19s=";
      filelist = files;
    }
    |> splitFiles files;
}
