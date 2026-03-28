{ fetchSteamCards, ... }:
{
  grimFandangoRemastered = fetchSteamCards {
    appId = 205720;
    hash = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
    cardNames = [
      "grimFandango"
      "onTheWaterfront"
    ];
  };
}
