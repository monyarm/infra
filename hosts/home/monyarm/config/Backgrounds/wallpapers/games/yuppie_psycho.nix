{ fetchSteamCards, ... }:
{
  yuppiePsycho = fetchSteamCards {
    appId = 597760;
    cardNames = [
      "welcomeToSintracorp"
      "awakening"
    ];
    sha256 = "sha256-BwTNKFlIAAu0cb6+7+3XVkMh5ZZAJi6K9hUCMMOv/uk=";
  };
}
