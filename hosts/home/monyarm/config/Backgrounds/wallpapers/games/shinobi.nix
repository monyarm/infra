{ fetchSteamCards, ... }:
{
  shinobiArtOfVengeance = fetchSteamCards {
    appId = 2361770;
    cardNames = [
      "yamato"
      "ankou"
      "tomoe"
      "naoko"
      "joeMusashi"
      "lordRuse"
      "chiyo"
    ];
    sha256 = "sha256-18z9munWTvHPIgAC8guz1XJ/SUB7TpNPFdj/A4eHL24=";
  };
}
