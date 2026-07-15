{ fetchSteamCards, ... }:
{
  battleChefBrigade = fetchSteamCards {
    appId = 452570;
    cardNames = [
      "kirin"
      "thrash"
      "ziggy"
      "mina"
      "kamin"
    ];
    sha256 = "sha256-tl1z8O2WjAP8HvzI4+wCuh+klptvbE/eSMLWj9OTMMI=";
  };
}
