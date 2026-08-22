{ fetchSteam, splitFiles, ... }:
{
  zenoClash =
    let
      files = [
        "extras/PromoArt_MaxResolution/JustinChan.png"
        "extras/PromoArt_MaxResolution/ThomasShahan.png"
      ];
    in
    fetchSteam {
      appId = 247080;
      depotId = 379400;
      manifestId = 441937160032073935;
      sha256 = "sha256-G8ySRqKt5MU1MCtEoc13lQPd2dX1ZjuoJOkuzx+ukss=";
      filelist = files;
    }
    |> splitFiles files;

  zenoClash2 =
    let
      files = [
        "Wallpapers/wallpaper_b_3840.png"
        "Wallpapers/wallpaper_a_3840.png"
      ];
    in
    fetchSteam {
      appId = 215690;
      depotId = 215691;
      manifestId = 870559019708799916;
      sha256 = "sha256-QYKBgWkF3SE0UgXVw7D6kEemfHpaRA6L5a9flptR7b0=";
      filelist = files;
    }
    |> splitFiles files;
}
