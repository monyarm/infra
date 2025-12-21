{ fetchSteamCards, ... }:
{
  guacamelee = fetchSteamCards {
    appId = 275390;
    cardNames = [ "calaca" ];
    hash = "sha256-czqfB601aSAO35CXdLz6QepbuKYfwTjfaySUi1yAbNY=";
  };
}
