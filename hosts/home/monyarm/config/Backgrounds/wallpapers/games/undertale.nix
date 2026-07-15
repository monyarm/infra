{ fetchSteamCards, ... }:
{
  undertale = fetchSteamCards {
    appId = 391540;
    cardNames = [
      "flowey"
      "toriel"
      "sans"
      "undyne"
      "papyrus"
    ];
    sha256 = "sha256-FFdrw/xefYoWKXYMZwbR5KRUFYeGsRtxwWOTAmBE+7E=";
  };
}
