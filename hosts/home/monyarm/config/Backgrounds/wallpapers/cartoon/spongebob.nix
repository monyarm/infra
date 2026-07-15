{ fetchSteamCards, ... }:
{
  spongebobTitansOfTheTide = fetchSteamCards {
    appId = 2479650;
    cardNames = [
      "kingNeptune"
      "flyingDutchman"
      "captainGoldie"
      "kassandra"
      "stinger"
      "olBoomerGhost"
      "chocolateTom"
      "grandSlammerGhost"
    ];
    sha256 = "sha256-RJBhl25cS9+RpTU5ssOSjJ0S/sPEZmvLT9QZLnFWE0k=";
  };
  spongebobCosmicShake = fetchSteamCards {
    appId = 1282150;
    cardNames = [
      "medievalPearl"
      "kassandra"
      "westernKrabs"
      "karateSandy"
      "squidward"
      "halloweenGary"
      "piratesPrawn"
      "prehistoricPompom"
      "gloveWorldGlovy"
    ];
    sha256 = "sha256-rl5LfxJ3xOl7yZzsNogZ60iR58GxuyJoSmUguKuw7sA=";
  };
}
