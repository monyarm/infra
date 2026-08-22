{
  fetchSteamCards,
  fetchGOG,
  splitFiles,
  ...
}:
{
  grimFandangoRemastered = fetchSteamCards {
    appId = 316790;
    cardNames = [
      "grimFandango"
      "onTheWaterfront"
    ];
    sha256 = "sha256-ynqpabFRGO4wrEtrPTQyOyBh2bK+fi+/9/74QuIvbqo=";
  };
  grimFandangoWallpapers =
    fetchGOG {
      game = "grim_fandango_remastered";
      fileId = 39133;
      sha256 = "sha256-zpY7/BYTmkPmGWpckBeKWxlVgxJxTjMZVx1T4NJNoSU=";
    }
    |> splitFiles [
      "gf_remastered_wallpaper/wallpaper-1-Grim-Fandango.jpg"
    ];
}
