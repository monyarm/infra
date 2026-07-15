{ fetchSteamCards, ... }:
{
  murderedSoulSuspect = fetchSteamCards {
    appId = 233290;
    cardNames = [
      "morgue"
      "graffiti"
      "graveyard"
      "cemetary"
      "exterior"
      "investigation"
      "ghostWall"
    ];
    sha256 = "sha256-LnFrMOUqZVwfUZqpUza68vuiRoh9ReTWsnGbjbG5fvM=";
  };
}
