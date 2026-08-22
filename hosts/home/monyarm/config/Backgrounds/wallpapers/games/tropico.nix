{ fetchGOG, getFile, ... }:
{
  tropico4 =
    fetchGOG {
      game = "tropico_4";
      fileId = 57263;
      sha256 = "sha256-z+6XTZyrAlSSaYz4cGQA8pOjyg+vUIu8CxC80izU4Uo=";
    }
    |> getFile "tropico_4_wallpaper/wallpaper_tropico_4_3200x1800.jpg";
}
