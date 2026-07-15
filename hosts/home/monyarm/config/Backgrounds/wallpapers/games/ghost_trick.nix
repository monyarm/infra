{ fetchSteamCards, ... }:
{
  ghostTrickPhantomDetective = fetchSteamCards {
    appId = 1967430;
    cardNames = [
      "inspectorCabanela"
      "commanderSith"
      "justiceMinister"
      "missile"
      "sissel"
      "oneStepAheadTengo"
      "beauty"
      "maskedMuscleman"
      "jowd"
      "alma"
      "kamila"
      "nearsightedJeego"
      "lynne"
      "ray"
      "dandy"
    ];
    sha256 = "sha256-2Cv7pWio3OqQGJQ52ls5M/F4KdFCvtjblV7ZXgbTTSg=";
  };
}
