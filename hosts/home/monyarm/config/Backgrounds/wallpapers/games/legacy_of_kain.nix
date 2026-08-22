{ fetchGOG, splitFiles, ... }:
{
  legacyOfKainDefiance =
    fetchGOG {
      game = "legacy_of_kain_defiance";
      fileId = 17543;
      sha256 = "sha256-zieI89uTZTVl8E2Fuln9BQ3iAUmvJYsa79liJZwGnCY=";
    }
    |> splitFiles [
      "loc_defiance_wallpapers/Wallpaper1_Defiance_1920x1080.jpg"
      "loc_defiance_wallpapers/Wallpaper3_Defiance_1920x1080.jpg"
      "loc_defiance_wallpapers/Wallpaper5_Defiance_1920x1080.jpg"
      "loc_defiance_wallpapers/Wallpaper2_Defiance_1920x1080.jpg"
      "loc_defiance_wallpapers/Wallpaper4_Defiance_1920x1080.jpg"
    ];
}
