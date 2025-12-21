{ fetchSteamCards, ... }:
{
  monsterProm = fetchSteamCards {
    appId = 743450;
    hash = "sha256-ydtfjTAy+THbmsL7G0k36I/t0lcHxPKOnb/zflrW/YQ=";
  };
}
