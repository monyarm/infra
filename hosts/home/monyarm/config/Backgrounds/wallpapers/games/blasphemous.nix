{
  fetchSteamCards,
  fetchSteam,
  splitFiles,
  ...
}:
{
  blasphemous = fetchSteamCards {
    appId = 774361;
    cardNames = [
      "quirceReturnedByTheFlames"
      "esdrasOfTheAnointedLegion"
      "melquAdesTheArchbishop"
      "crisantaOfTheWrappedAgony"
      "ourLadyOfTheCharredVisage"
      "tresAngustias"
      "hisHolinessEscribar"
      "tenPiedad"
      "perpetvaOfTheAnointedLegion"
    ];
    sha256 = "sha256-LaGiX4dMtlec9+FC9w7FKoRktiHhU1tmiQGS7o7U/2c=";
  };
  blasphemousWallpapers =
    let
      files = [
        "Blasphemous - Wallpapers/Blasphemous-wallpaper-full-HD-1.png"
        "Blasphemous - Wallpapers/wallpapers-full-HD-2.png"
      ];
    in
    fetchSteam {
      appId = 774361;
      depotId = 1143854;
      manifestId = 7538235104894025746;
      sha256 = "sha256-h8lZskyn8Z6plwq02gKGt5JaySAIwV56dhUMBsTfacE=";
      filelist = files;
    }
    |> splitFiles files;
}
