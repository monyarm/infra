{ fetchSteamCards, ... }:
{
  shovelKnight = fetchSteamCards {
    appId = 250760;
    cardNames = [
      "wanderersOfTheWild"
      "honoredHeroes"
      "theBlueBurrower"
      "welcomeToTheValley"
      "halfwayToDestiny"
      "endOfTheOrder"
      "fantasticFoes"
      "talkativeTownsfolk"
    ];
    sha256 = "sha256-h2wsDDBnZ2NzqhWxQJIHNJsvZQfVmyq9kVZcZV4AC9g=";
  };
  shovelKnightSpecterOfTorment = fetchSteamCards {
    appId = 589510;
    cardNames = [
      "shadowsOfThePast"
      "friendlyFiends"
      "reize"
      "greedyShadows"
      "specterOfTorment"
    ];
    sha256 = "sha256-YJBxVj7UJEg8MaIaiQqEJTuEIA2EdwPcmOVTc4GHIUg=";
  };
  shovelKnightShovelOfHope = fetchSteamCards {
    appId = 589500;
    cardNames = [
      "anchorManagement"
      "hailTheTrouppleKing"
      "bodySwapTheEnchanter"
      "shovelingTogether"
      "campfire"
      "bodySwapShovelAndShield"
    ];
    sha256 = "sha256-lt95A/Pf6fQUO45MYvoAkTKK7XSYwk9/lfRbUoZLDkI=";
  };
}
