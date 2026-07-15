{ fetchSteamCards, ... }:
{
  celeste = fetchSteamCards {
    appId = 504230;
    cardNames = [
      "theo"
      "badeline"
      "mrOshiro"
      "madeline"
      "granny"
    ];
    sha256 = "sha256-GUtdjkUME3d0NGFbTlr7WmxIDPlRhOG7E+3lWri61TQ=";
  };
}
