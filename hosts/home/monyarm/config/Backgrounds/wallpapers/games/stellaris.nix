{ fetchSteamCards, ... }:
{
  stellaris = fetchSteamCards {
    appId = 281990;
    cardNames = [
      "divineMandate"
      "frienderation"
      "enlightenedMonarchy"
      "scienceDirectorate"
      "plutocraticOligarchy"
      "fallenEmpire"
    ];
    sha256 = "sha256-mM0w7AFMl+Ybd0nGgLaWReDsh+3CLKj1ktq+VvvoeLE=";
  };
}
