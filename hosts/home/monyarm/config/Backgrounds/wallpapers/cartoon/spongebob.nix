{ fetchSteamCards, ... }:
{
  spongebobTitansOfTheTide = fetchSteamCards {
    appId = 2479650;
    hash = "sha256-iBwe5B7XeXphhEg96iOSyaKF/2bca//Io7Iqw2QJ3vc=";
  };
  spongebobCosmicShake = fetchSteamCards {
    appId = 1282150;
    hash = "sha256-oxWRA+AGRw+h0FbODgmnaV7zMBOSn6zlvCYyiN1w1sc=";
  };
}
