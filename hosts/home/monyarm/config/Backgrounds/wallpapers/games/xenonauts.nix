{ fetchGOG, splitFiles, ... }:
{
  xenonauts =
    fetchGOG {
      game = "xenonauts";
      fileId = 31833;
      sha256 = "sha256-z+y9uFofvEPel4Hs39z73KGLX07JYvYjadzXl8Uz+Rg=";
    }
    |> splitFiles [
      "xenonauts_wallpapers/wallpaper-02-Xenonauts.jpg"
      "xenonauts_wallpapers/wallpaper-01-Xenonauts.jpg"
    ];
}
