{ fetchSteamCards, ... }:
{
  shantaePiratesCurse = fetchSteamCards {
    appId = 345820;
    cardNames = [
      "bolo"
      "summerShantae"
      "uncleMimic"
      "squidBaron"
      "shantaeFriends"
      "abnerAndPoe"
      "sky"
      "shantae"
      "costumeShantae"
      "rottytops"
      "tinkerbat"
      "riskyBoots"
    ];
    sha256 = "sha256-hCW8PqUeTm7U2/SNragtxaXFcpWcwRdWk+qRn7wk+x4=";
  };
}
