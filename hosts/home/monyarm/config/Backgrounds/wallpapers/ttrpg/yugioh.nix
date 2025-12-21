{ fetchSteamCards, ... }:
{
  duelLinks = fetchSteamCards {
    appId = 601510;
    hash = "sha256-BC6Wbq8zamlJbDXR2q65UEsatGekRU/1pvbPTjAINfo=";
  };
  masterDuel = fetchSteamCards {
    appId = 1449850;
    hash = "sha256-GFRPqudd0Za+Bzy4TR1jKOFs8zBEnHlVo736gOFy6l8=";
  };
}
