{ fetchSteamCards, ... }:
{
  hollowKnight = fetchSteamCards {
    appId = 367520;
    hash = "sha256-+5u6hfj1fKusWp0GrEmm6Ru9KFBr3HF830s+c7aPiJk=";
  };
  silksong = fetchSteamCards {
    appId = 1030300;
    hash = "sha256-bwvQOZloY/yCDDlztQMD1xCaqpxM8NO+TSSSLAq2MqQ=";
  };
}
