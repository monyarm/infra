{ fetchSteamCards, ... }:
{
  yuppiePsycho = fetchSteamCards {
    appId = 1106430;
    hash = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
    cardNames = [
      "welcomeToSintracorp"
      "awakening"
    ];
  };
}
