{ fetchSteamCards, ... }:
{
  nierAutomata = fetchSteamCards {
    appId = 524220;
    hash = "sha256-9lekfACutxxzrsQWMRN4BjuSnCO/klq2I+jfJoWUc2k=";
  };
  nierReplicant = fetchSteamCards {
    appId = 1113560;
    hash = "sha256-Xy2M0v4y2pvXHohDEiqsNCSwvO9pSxFsmMgp9KW378w=";
  };
}
