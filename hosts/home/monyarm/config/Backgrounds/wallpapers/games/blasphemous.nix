{ fetchSteamCards, ... }:
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
}
