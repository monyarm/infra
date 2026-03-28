{ fetchSteamCards, ... }:
{
  monsterProm = fetchSteamCards {
    appId = 743450;
    hash = "sha256-ydtfjTAy+THbmsL7G0k36I/t0lcHxPKOnb/zflrW/YQ=";
  };
  monsterProm2 = fetchSteamCards {
    appId = 1140270;
    hash = "sha256-C7v4fStAWezQwrznJu56Ir01byS+rsFGXFWRGeDF92g=";
  };
  monsterProm3 = fetchSteamCards {
    appId = 1665190;
    hash = "sha256-M1N1ySVXZdNyIcAVto8g/GPe19n8cwgzqCfXEB1rCy8=";
  };
}
