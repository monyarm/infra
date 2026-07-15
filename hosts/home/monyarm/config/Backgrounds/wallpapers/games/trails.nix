{ fetchSteamCards, ... }:
{
  trailsInTheSkySC = fetchSteamCards {
    appId = 251290;
    cardNames = [
      "introducingRenne"
      "girlsOnlySleepover"
      "naptime"
      "firstSignOfWinter"
      "cleaningDuty"
      "fantasticParty"
      "cheers"
      "gotcha"
    ];
    sha256 = "sha256-hXNI+kkZ0P1drPhUxsSp5VfyTRoeYworEx3+XF7Wd34=";
  };
}
