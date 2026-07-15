{ fetchSteamCards, ... }:
{
  va11halla = fetchSteamCards {
    appId = 447530;
    cardNames = [
      "almaArmas"
      "jillStingray"
      "danaZane206x"
      "dorothyHaze"
      "stellaHoshii"
    ];
    sha256 = "sha256-5cfEdg5Xz4+hopTYRp7a0by8kNjl93ivH3Y4v0+3eTk=";
  };
}
