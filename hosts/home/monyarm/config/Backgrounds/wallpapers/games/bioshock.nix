{ fetchSteamCards, ... }:
{
  bioshockInfinite = fetchSteamCards {
    appId = 8870;
    cardNames = [
      "fireman"
      "elizabeth"
      "motorizedPatriot"
      "songbird"
      "boysOfSilence"
      "handyman"
      "luteceTwins"
    ];
    sha256 = "sha256-Ac8yLzDbAhhqHnOaNoZ/D1MbGp330nvTisepdmWfkWw=";
  };
}
