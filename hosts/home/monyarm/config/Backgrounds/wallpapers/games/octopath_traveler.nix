{ fetchSteamCards, ... }:
{
  octopathTraveler = fetchSteamCards {
    appId = 921570;
    cardNames = [
      "alfynGreengrass"
      "primroseAzelhart"
      "tressaColzione"
      "hAanit"
      "ophiliaClement"
      "cyrusAlbright"
      "olbericEisenberg"
      "therion"
    ];
    sha256 = "sha256-k4GOrGS4dU9IHi6kj40VtZBUucEbw0/nn2cyJCO0iwI=";
  };
  octopathTraveler0 = fetchSteamCards {
    appId = 3014320;
    cardNames = [
      "ludo"
      "celsus"
      "stia"
      "alexia"
      "phenn"
      "laurana"
      "theProtagonist"
      "macy"
    ];
    sha256 = "sha256-/UT5GAYOOD3oyiIN/jysf4t/Q3fq/VWU+cd+hLUR0oM=";
  };
}
