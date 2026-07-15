{ fetchSteamCards, ... }:
{
  bloodrayneTerminalCut = fetchSteamCards {
    appId = 1373510;
    cardNames = [
      "drBThoryMengele"
      "jRgenWulf"
      "rayneTheDhampir"
      "rayneTheAssassin"
      "mynce"
    ];
    sha256 = "sha256-TmdglrlHpm2leNI9Sm3/TuefGaHOIq3YymV3+vdAjE8=";
  };
  bloodrayne2TerminalCut = fetchSteamCards {
    appId = 1373550;
    cardNames = [
      "ephemera"
      "kagan"
      "battleRayne"
      "formalRayne"
      "ferril"
    ];
    sha256 = "sha256-KlpXBJeXRkw+IilNjnKggjD7JKDiY3IBftYJ+tpJCNs=";
  };
}
