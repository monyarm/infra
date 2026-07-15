{ fetchSteamCards, ... }:
{
  nierAutomata = fetchSteamCards {
    appId = 524220;
    cardNames = [
      "emil"
      "adam"
      "devola"
      "eve"
      "theCommander"
      "card2b"
      "a2"
      "card9s"
      "popola"
    ];
    sha256 = "sha256-Cbzvk/1tOFDQdPIir2cdUwCO6uqK/uIM7l23xtwZpBM=";
  };
  nierReplicant = fetchSteamCards {
    appId = 1113560;
    cardNames = [
      "louise"
      "emil"
      "no7"
      "playerFirstHalf"
      "playerSecondHalf"
      "fyra"
      "kain"
      "kingOfFacade"
      "yonahSecondHalf"
      "yonahFirstHalf"
    ];
    sha256 = "sha256-EmZXHlu2S94pRb64ruXWCqWRYBkibiY9ptdRtG+JxW8=";
  };
}
