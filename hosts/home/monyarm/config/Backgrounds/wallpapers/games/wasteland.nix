{ fetchGOG, splitFiles, ... }:
{
  wasteland2 =
    fetchGOG {
      game = "wasteland_2_directors_cut";
      fileId = 35373;
      sha256 = "sha256-FleknfDahC5CpwEPtdfKlV5Nsq4FkAtCK9Csat9JK2o=";
    }
    |> splitFiles [
      "wallpaper-3-2560x1440-Wasteland-2.jpg"
      "wallpaper-1-2560x1440-Wasteland-2.jpg"
      "wallpaper-2-2560x1440-Wasteland-2.jpg"
    ];
}
