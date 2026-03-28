{ fetchSteamCards, ... }:
{
  secretOfMana = fetchSteamCards {
    appId = 637670;
    hash = "sha256-HNMhmSGsT3iKh0F3Xvfi3wyAsCol2CmaBlISyXe9k0U=";
  };
}
