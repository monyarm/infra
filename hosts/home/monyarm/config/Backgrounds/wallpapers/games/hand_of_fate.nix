{ fetchGOG, splitFiles, ... }:
{
  handOfFate =
    fetchGOG {
      game = "hand_of_fate";
      fileId = [
        40723
        40733
      ];
      sha256 = "sha256-+7bm3sSralfBO5rD2mmEqNyHU8pTKqXfzphtwmTr+bM=";
    }
    |> splitFiles [
      "hof_wallpapers/wallpaper-02-Hand-of-Fate-1920x1080.jpg"
      "hof_wallpapers/wallpaper-01-Hand-of-Fate-1920x1080.jpg"
      "hof_artwork/Hero_artwork.png"
      "hof_wallpapers/wallpaper-03-Hand-of-Fate-1920x1080.jpg"
    ];
}
