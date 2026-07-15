{ fetchSteamCards, ... }:
{
  tmntShredderRevenge = fetchSteamCards {
    appId = 1361510;
    cardNames = [
      "donatello"
      "leonardo"
      "april"
      "raphael"
      "michelangelo"
      "splinter"
    ];
    sha256 = "sha256-pEhvajuJJFCJswFMjcIINrZu7EOZRRQzKZEOT2eHi2I=";
  };
}
