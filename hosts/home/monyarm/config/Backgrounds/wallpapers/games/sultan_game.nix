{ fetchSteamCards, ... }:
{
  sultanGame = fetchSteamCards {
    appId = 3117820;
    cardNames = [
      "iman"
      "maggie"
      "riel"
      "theSultan"
      "fardak"
      "mahir"
      "adila"
      "ladyBecky"
      "nawfal"
      "lumera"
      "arzu"
      "nabhani"
    ];
    sha256 = "sha256-/eP6Yze7+t+C/SNvPEE/+1pNmk5e7hmc1hBsFcj33GM=";
  };
}
