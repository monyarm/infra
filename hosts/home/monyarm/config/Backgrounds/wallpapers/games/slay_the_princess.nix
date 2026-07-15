{ fetchSteamCards, ... }:
{
  slayThePrincess = fetchSteamCards {
    appId = 1989270;
    cardNames = [
      "thePrisoner"
      "theAdversary"
      "theRazor"
      "theStranger"
      "theWitch"
      "theDamsel"
      "theBeast"
      "theSpectre"
      "theTower"
      "theNightmare"
    ];
    sha256 = "sha256-zfSEVr9x6rwHhsbJ/BqFz2qtgMdUkqpFzjgeYmHj0zQ=";
  };
}
