{ fetchSteamCards, ... }:
{
  ysXProudNordics = fetchSteamCards {
    appId = 3949290;
    cardNames = [
      "lilaMistral"
      "canuteGamley"
      "astridZayren"
      "namelessOldMan"
      "adolChristin"
      "karjaBalta"
    ];
    sha256 = "sha256-fzCx1ahkrE6WGZzQVaMuqNhJKorQ6eyzk12RTomhRFg=";
  };
}
