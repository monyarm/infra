{ fetchSteamCards, ... }:
{
  rhapsodyAMusicalAdventure = fetchSteamCards {
    appId = 1866430;
    cardNames = [
      "cornet"
      "marjoly"
      "ferdinandMarlE"
      "etoileRosenqueen"
      "kururu"
    ];
    sha256 = "sha256-eyvtrthI8BXgpfN+LjrAdy0LzYUdMcSImAZSmL9cPh8=";
  };
}
