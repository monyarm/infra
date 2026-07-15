{ fetchSteamCards, ... }:
{
  seedsOfChaos = fetchSteamCards {
    appId = 1205950;
    cardNames = [
      "alexia"
      "jezera"
      "shaya"
      "rowan"
    ];
    sha256 = "sha256-n3X8Zo4tu/87Ca6xmGvOUbhFBA9RM+jjwHsvKxUGCr8=";
  };
}
