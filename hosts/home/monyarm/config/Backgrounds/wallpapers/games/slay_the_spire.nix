{ fetchSteamCards, ... }:
{
  slayTheSpire = fetchSteamCards {
    appId = 646570;
    cardNames = [
      "donuDeca"
      "bronzeAutomaton"
      "theGuardian"
      "theCollector"
      "slimeBoss"
      "hexaghost"
      "awakenedOne"
      "timeEater"
      "theChamp"
    ];
    sha256 = "sha256-L9TDqc4ytPAva00Amx+FMDffIUKN0CHIminxzxc8EGU=";
  };
}
