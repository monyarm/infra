{ fetchSteamCards, ... }:
{
  grimFandangoRemastered = fetchSteamCards {
    appId = 316790;
    cardNames = [
      "grimFandango"
      "onTheWaterfront"
    ];
    sha256 = "sha256-ynqpabFRGO4wrEtrPTQyOyBh2bK+fi+/9/74QuIvbqo=";
  };
}
