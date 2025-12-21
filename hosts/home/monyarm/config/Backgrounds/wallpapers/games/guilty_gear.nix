{ fetchSteamCards, ... }:
{
  bridget = fetchSteamCards {
    appId = 348550;
    cardNames = [ "bridget" ];
    hash = "sha256-bsPs3XLlfMu3xq3Pv/HhR+1jmD0CPdrVSlhQnOHl+KY=";
  };
}
