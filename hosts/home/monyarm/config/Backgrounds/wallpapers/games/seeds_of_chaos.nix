{ fetchSteamCards, ... }:
{
  seedsOfChaos = fetchSteamCards {
    appId = 1205950;
    cardNames = [
      "alexia"
      "jezera"
      "clamin"
      "shaya"
      "rowan"
    ];
    hash = "sha256-DChUq51A2vzdwYkZBEBRDWf0c10hydBkvkztSoY3Orw=";
  };
}
