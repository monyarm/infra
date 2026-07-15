{ fetchSteamCards, ... }:
{
  bravelyDefaultFlyingFairyHD = fetchSteamCards {
    appId = 2833580;
    cardNames = [
      "ringabel"
      "agnS"
      "edea"
      "airy"
      "tiz"
    ];
    sha256 = "sha256-+YqOw5pxEa1DS5jXe7fHZPcFOFRYxx1muDlfCBdBgcM=";
  };
}
