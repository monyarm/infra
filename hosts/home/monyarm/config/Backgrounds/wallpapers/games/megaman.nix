{ fetchSteamCards, ... }:
{
  megamanZeroZX = fetchSteamCards {
    appId = 999020;
    hash = "sha256-DsdPiSsjoGYLmkFKxSs8CY6F2EONtyob1qHGngmfZUw=";
  };
  megamanBattleNetwork = fetchSteamCards {
    appId = 1798010;
    hash = "sha256-TC0aSx+uLh/OunCJ41kfnllRIHRra7O6tgJEUtazjuw=";
  };
}
