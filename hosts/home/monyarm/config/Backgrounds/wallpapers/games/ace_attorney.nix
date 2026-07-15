{ fetchSteamCards, ... }:
{
  aceAttorneyTrilogy = fetchSteamCards {
    appId = 787480;
    cardNames = [
      "phoenixWright"
      "pearlFey"
      "milesEdgeworth"
      "franziskaVonKarma"
      "godot"
      "mayaFey"
      "emaSkye"
      "miaFey"
    ];
    sha256 = "sha256-qEbuauxJpNSfG1KgDNcJR1DzifLV+QDOjgQmUZamgEs=";
  };
}
