{ fetchSteamCards, ... }:
{
  massEffectLegendaryEdition = fetchSteamCards {
    appId = 1328670;
    cardNames = [
      "liara"
      "tali"
      "charactermontage"
      "garrus"
      "thane"
      "miranda"
    ];
    sha256 = "sha256-yRwSbfZuAA+n35oWH5kasrIn5+JOB3lNuv1kZDDQaOE=";
  };
}
