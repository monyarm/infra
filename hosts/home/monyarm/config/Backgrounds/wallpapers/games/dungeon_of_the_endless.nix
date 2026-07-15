{ fetchSteamCards, ... }:
{
  dungeonOfTheEndless = fetchSteamCards {
    appId = 249050;
    cardNames = [
      "frozenGrounds"
      "jungleFever"
      "endlessLaboratory"
      "necrophageNest"
      "sewerMaze"
      "drakkenSanctuary"
    ];
    sha256 = "sha256-H+pYE3gGAgwjqKV+DWuzb6rngm9cY1tBBIlKYdCHq+8=";
  };
}
