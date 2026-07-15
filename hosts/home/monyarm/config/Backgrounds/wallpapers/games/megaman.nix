{ fetchSteamCards, ... }:
{
  megamanZeroZX = fetchSteamCards {
    appId = 999020;
    cardNames = [
      "megamanZxAdvent"
      "megamanZero2"
      "megamanZx"
      "megamanZero3"
      "megamanZero4"
      "megamanZero"
    ];
    sha256 = "sha256-QQF1qxywQAp47mIz1E58fb+Rs1va3by25nSJtQhcLmE=";
  };
  megamanBattleNetwork = fetchSteamCards {
    appId = 1798010;
    cardNames = [
      "punkMrFamous"
      "glideYai"
      "numbermanHigsby"
      "megamanLanVol1"
      "heatmanMrMatch"
      "toadmanRabitta"
      "rollMayl"
      "gutsmanDex"
      "kingmanTora"
      "lifevirusWily"
    ];
    sha256 = "sha256-wT1oTJrUdAUibye1O6rLZZr4lVbRO6v1DJ33QtUtANs=";
  };
  megaManStarForceLegacyCollection = fetchSteamCards {
    appId = 3500390;
    cardNames = [
      "brother4"
      "brother1"
      "brother2"
      "wizard"
      "brother3"
      "hero2"
      "hero1"
    ];
    sha256 = "sha256-EkoibmfDyBqruNU+yTvOKzhdmqDQL3Fsyio4hDhB42I=";
  };
}
