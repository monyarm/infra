{ fetchSteamCards, ... }:
{
  shantaePiratesCurse = fetchSteamCards {
    appId = 345820;
    cardNames = [
      "summerShantae"
      "shantaeFriends"
      "costumeShantae"
      "riskyBoots"
      "rottyTops"
      "shantae"
      "sky"
    ];
    hash = "sha256-i2P5JPEX0IwGdV1Yc0jN+uY4qS4YIHF3X4CWoAdBQNs=";
  };
}
