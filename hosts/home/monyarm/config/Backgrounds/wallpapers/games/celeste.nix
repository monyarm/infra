{ fetchSteamCards, ... }:
{
  celeste = fetchSteamCards {
    appId = 504230;
    hash = "sha256-xnHi8zhmpyQUHYojyHObjBRCrA/J3oexR1txg4w77MQ=";
  };
}
