{ fetchMyNintendo, getFile, ... }:
{
  prime4Beyond =
    fetchMyNintendo {
      url = "https://my.nintendo.com/rewards/617c8dd801bffa2f/media/6e2e98b939ce9701";
      sha256 = "sha256-gQs5nPLI1nSgOWylk6x4Yy8+6kuY7/1m+9qE4kPZ+ps=";
    }
    |> getFile "Metroid_Prime_4_Beyond_wallpaper_1920x1080.jpg";
}
