{ fetchSteamCards, ... }:
{
  bloodrayneTerminalCut = fetchSteamCards {
    appId = 1373510;
    hash = "sha256-UoevVw04vjxOxNdM2HiRPEKftdZTzoD9uSbi8mZZn2Q=";
  };
  bloodrayne2TerminalCut = fetchSteamCards {
    appId = 1373550;
    hash = "sha256-VbnerJyPdE3+Z1aQbKKmc5wYDV3eVI0c4+3cOWdyE6c=";
  };
}
