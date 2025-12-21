{ fetchSteamCards, ... }:
{
  papersPlease = fetchSteamCards {
    appId = 239030;
    cardNames = [
      "passports"
      "theOrderOfTheEzicStar"
    ];
    hash = "sha256-wVo/YMkyx3DNBXCb4+V6wbvIBhmPR9+LksdXaPNlo7E=";
  };
}
