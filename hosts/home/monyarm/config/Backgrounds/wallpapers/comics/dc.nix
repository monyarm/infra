{ fetchSteamCards, ... }:
{
  arkhamCityGame = fetchSteamCards {
    appId = 200260;
    cardNames = [
      "twoFace"
      "mrFreeze"
      "joker"
      "riddler"
      "batman"
      "penguin"
      "catwoman"
    ];
    sha256 = "sha256-5amwm79EZulDpj4tDSCA7USBWPop0+erBdIFCKHVDm4=";
  };
}
