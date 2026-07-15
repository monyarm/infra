{ fetchSteamCards, ... }:
{
  haloSpartanAssault = fetchSteamCards {
    appId = 277430;
    cardNames = [
      "covenantLeader"
      "spartanPalmer"
      "spartanDavis"
      "covenantShips"
      "draetheusV"
      "unscInfinity"
    ];
    sha256 = "sha256-SA3czH5wG0Qx3/YVmr9JiI1WKOLfrDOmY0DDNwmgEyQ=";
  };
}
