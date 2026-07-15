{ fetchSteamCards, ... }:
{
  bridget = fetchSteamCards {
    appId = 348550;
    cardNames = [ "bridget" ];
    sha256 = "sha256-4sjOaqmLfI7v/H5ySyZZEXDB8k7g7B7g7hxuVKP24qI=";
  };
  guiltyGearX2 = fetchSteamCards {
    appId = 314030;
    cardNames = [
      "ggRMay"
      "ggREddie"
      "ggRSolBadguy"
      "ggRAxlLow"
      "ggRBridget"
      "ggRVenom"
      "ggRDizzy"
      "ggRMillia"
      "ggRKy"
      "ggRZappa"
      "ggRSlayer"
    ];
    sha256 = "sha256-hODc04qotsj73LV2uAaW9lH3O2K0DtZVwMbz0Z0p6yg=";
  };
}
