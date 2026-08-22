{ fetchGOG, getFile, ... }:
{
  huniepop =
    fetchGOG {
      game = "huniepop";
      fileId = 61163;
      sha256 = "sha256-8DFZwXp+IYGKU08JOoQM2H5KS/b47OAQPRAlW3xpVo4=";
    }
    |> getFile "huniepop_wallpaper/wallpaper-3200x1800_huniepop.jpg";
}
