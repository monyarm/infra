{ fetchGOG, splitFiles, ... }:
{
  ascendant =
    fetchGOG {
      game = "ascendant";
      fileId = 31183;
      sha256 = "sha256-NSV3l5f/mUgfWfWPXp3bxoP/AI9ZJOe0KtZfFYN+8EI=";
    }
    |> splitFiles [
      "ascendant_wallpapers/wallpaper-03-Ascendant.jpg"
      "ascendant_wallpapers/wallpaper-01-Ascendant.jpg"
      "ascendant_wallpapers/wallpaper-02-Ascendant.jpg"
    ];
}
