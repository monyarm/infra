{ fetchSteamCards, ... }:
{
  talesOfSeikyu = fetchSteamCards {
    appId = 2340520;
    cardNames = [
      "kon"
      "yuiOda"
      "yoni"
      "musashi"
      "nyotengu"
      "leon"
      "mika"
      "missAma"
      "shuten"
      "romanticFlight"
      "torleone"
      "hephaestus"
      "seabert"
      "sasaki"
      "anna"
    ];
    sha256 = "sha256-5UTLOxTYcU7zYfrd1+9NR19wABOEQ8TFZZ1+A5bkuGw=";
  };
}
