{ fetchSteamCards, ... }:
{
  arkhamCityGame = fetchSteamCards {
    appId = 200260;
    hash = "sha256-jJz1l64CJeJavkOzFKtroPhYr0S8z76k3/qg3uhkL9w=";
  };
}
