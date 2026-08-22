{
  fetchGOG,
  splitFilesWith,
  image,
  ...
}:
with image;
{
  riseOfTheTriad =
    let
      files = [
        { file = "rott_2013_wallpapers/Wallpaper2 Rise of the Triad 1920x1080.jpg"; }
        { file = "rott_2013_wallpapers/Wallpaper3 Rise of the Triad 1920x1080.jpg"; }
        { file = "rott_2013_wallpapers/Wallpaper1 Rise of the Triad 1920x1080.jpg"; }
        {
          file = "rott_2013_artworks/Interior_LEVEL1.jpg";
          transform = crop16x9;
        }
      ];
    in
    fetchGOG {
      game = "rise_of_the_triad";
      fileId = [
        23423
        23403
      ];
      sha256 = "sha256-N4FOvvt6pBAK/taFIb4pYU6VvTttAk0TEw+8fXhu8dQ=";
    }
    |> splitFilesWith files;
}
