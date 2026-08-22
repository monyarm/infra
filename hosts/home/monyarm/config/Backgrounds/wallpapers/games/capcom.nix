{ fetchSteam, getFile, ... }:
{
  capcomArcade =
    let
      file = "Wallpaper/CAS_Wallpaper_10.png";
    in
    fetchSteam {
      appId = 1515950;
      depotId = 1515951;
      manifestId = 8730299595221726936;
      sha256 = "sha256-1wMCzDPSWjvN2KJ7ehvy+kqyVgGibkG4vFudGr0z1Ow=";
      filelist = [ file ];
    }
    |> getFile file;
}
