{ fetchSteamCards, ... }:
{
  okami = fetchSteamCards {
    appId = 587620;
    cardNames = [
      "theSunGodAmaterasu"
      "yomigami"
      "yumigami"
      "gekigami"
      "itegami"
      "tachigamiKabegami"
      "bakugami"
      "nuregami"
      "kasugami"
      "moegami"
      "kazegami"
      "sakigamiHasugamiTsutagami"
    ];
    sha256 = "sha256-L6xgpbUmKTD6/Ux2s2L/H/XJb4sgj7uFV6KC644qCSw=";
  };
}
