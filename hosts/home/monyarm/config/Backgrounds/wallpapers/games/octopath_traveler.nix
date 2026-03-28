{ fetchSteamCards, ... }:
{
  octopathTraveler = fetchSteamCards {
    appId = 921570;
    hash = "sha256-BnMrqKEXbrg5FCoYSyjDMODI+1cessOUyBj8EgAWqVI=";
  };
  octopathTraveler0 = fetchSteamCards {
    appId = 3014320;
    hash = "sha256-SnhH/1HzwJho7ei1gGvg0wnYgNNVx9i+tf4h7m5weNE=";
  };
}
