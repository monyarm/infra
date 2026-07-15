{ fetchSteamCards, ... }:
{
  saphireSaffari = fetchSteamCards {
    appId = 1526900;
    cardNames = [
      "predatorsAssemble"
      "sporedMalous"
      "noEscape"
      "freshSpores"
      "cavalcade"
    ];
    sha256 = "sha256-2i6iLPnDkC3OT4FVTE0SDnOONaB0NoeGG4mU0ekSj0Q=";
  };
}
