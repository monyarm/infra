{ fetchSteamCards, ... }:
{
  guacamelee = fetchSteamCards {
    appId = 275390;
    cardNames = [ "calaca" ];
    sha256 = "sha256-tD7PhN7J6HqAtlkSfRfW3fDm+E136OA2R1vVHdR5eeE=";
  };
}
