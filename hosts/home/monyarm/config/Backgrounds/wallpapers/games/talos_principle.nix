{ fetchSteam, getFile, ... }:
{
  talosPrinciple =
    let
      file = "BonusContent/Wallpapers/Talos_Wallpaper01.jpg";
    in
    fetchSteam {
      appId = 257510;
      depotId = 322021;
      manifestId = 8713693664225184971;
      sha256 = "sha256-0qU91JaZydpl+fiXtvKiKc8w7SE7GRWZ3UH7123DIYE=";
      filelist = [ file ];
    }
    |> getFile file;
}
