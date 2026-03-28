{ fetchSteamCards, ... }:
{
  bridget = fetchSteamCards {
    appId = 348550;
    cardNames = [ "bridget" ];
    hash = "sha256-bsPs3XLlfMu3xq3Pv/HhR+1jmD0CPdrVSlhQnOHl+KY=";
  };
  guiltyGearX2 = fetchSteamCards {
    appId = 314030;
    hash = "sha256-H5NUdtFus5vHL6ccKUcnd23e2FkeKPGX++bgGzgam0Y=";
  };
}
