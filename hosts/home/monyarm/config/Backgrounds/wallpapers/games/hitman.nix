{ fetchGOG, splitFiles, ... }:
{
  hitmanCodename47 =
    fetchGOG {
      game = "hitman_codename_47";
      fileId = 13573;
      sha256 = "sha256-w1ZqFA8J+Je26nq95CUw4/1YrgkNMcOUPw0k4DLKomI=";
    }
    |> splitFiles [
      "hitman_wallpapers/Hitman_wallpaper_2_1920x1080.jpg"
      "hitman_wallpapers/Hitman_wallpaper_3_1920x1080.jpg"
      "hitman_wallpapers/Hitman_wallpaper_1_1920x1080.jpg"
      "hitman_wallpapers/Hitman_wallpaper_4_1920x1080.jpg"
    ];
}
