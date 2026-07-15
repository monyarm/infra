{ fetchSteamCards, ... }:
{
  stardewValley = fetchSteamCards {
    appId = 413150;
    cardNames = [
      "sandy"
      "morris"
      "wizard"
      "gunther"
      "evelyn"
      "willy"
    ];
    sha256 = "sha256-japIA8049muMJoaz0PcFk9sVuWNU5xImOFcsarYQN4Q=";
  };
}
