{ fetchSteamCards, ... }:
{
  hellbreak = fetchSteamCards {
    appId = 3043760;
    cardNames = [
      "azrakash"
      "varkoth"
      "balzurath"
      "gholgoroth"
      "kharvex"
      "varZul"
      "malachor"
      "serathiel"
    ];
    sha256 = "sha256-EFaReT70ETRQuVeiCjcpDEaoZQJRimSDeOJ5GWXbhdI=";
  };
}
