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
  megaManStarForceLegacyCollection = fetchSteamCards {
    appId = 3500390;
    hash = "sha256-jBH2r2ps3bAb6d9CQ0jLAi/pqQtH2UW3pnGG6RnUMYk=";
  };
}
