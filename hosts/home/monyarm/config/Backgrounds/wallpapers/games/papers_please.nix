{ fetchSteamCards, ... }:
{
  papersPlease = fetchSteamCards {
    appId = 239030;
    cardNames = [
      "passports"
      "theOrderOfTheEzicStar"
    ];
    sha256 = "sha256-sIroWqYOQt/kzq593hXnqHjeTdcNICjHrXkG50MdH9s=";
  };
}
