{ fetchSteamCards, ... }:
{
  godsTrigger = fetchSteamCards {
    appId = 488730;
    cardNames = [ "onTheRocks" ];
    hash = "sha256-HU4pcEJdqpgV/VvNiGmx5PCpo4zGk7yJJFnhWre1rjc=";
  };
}
