{
  fetchSteamCards,
  pkgs,
  image,
  ...
}:
with image;
{
  warhammer40kGladius = fetchSteamCards {
    appId = 489630;
    cardNames = [
      "necronLord"
      "spaceMarinesVsNecrons"
      "gladiusPrime"
      "lordCommissar"
      "artefact"
      "spaceMarineCaptain"
      "warboss"
    ];
    sha256 = "sha256-rYcnQYGXF5gIqwLc20AtuBhpwTcUbwDFwhl+JzrQLyc=";
  };
  rogueTraderCRPG = fetchSteamCards {
    appId = 2186680;
    cardNames = [
      "yrliet"
      "seneschal"
      "pasqal"
      "marazhai"
      "jae"
      "sisterArgenta"
      "cassia"
      "ulfar"
      "idiraTlass"
      "vanCalox"
    ];
    sha256 = "sha256-buiKNH9cHi7jxI2mP21xNji/X/z/L19yfTpLbNGKWZ4=";
  };
  spaceMarine = pkgs.fetchurl {
    url = "https://assets.warhammer-community.com/sm-desktop.jpg";
    hash = "sha256-CYwGERtQIsdypMSnuNmLhcWS7/Toya0To2FubhR526E=";
  };
  tyranids = pkgs.fetchurl {
    url = "https://assets.warhammer-community.com/tyranids-desktop.jpg";
    hash = "sha256-P/RnpUrEXYzPCQ4vGCoL4jkvzLX2Dy2oXWkjQImzr8s=";
  };
  sisters = pkgs.fetchurl {
    url = "https://assets.warhammer-community.com/sisters-desktop.jpg";
    hash = "sha256-O8qN/9mAPycndzsG3xom1h4X+PwXbHuzIU6Kh0SZtco=";
  };
  necrons = pkgs.fetchurl {
    url = "https://assets.warhammer-community.com/necrons-desktop.jpg";
    hash = "sha256-+uSG0F5VGGX/i5l2C4KZAgnFJ30dqGUWXTU6Exp++zo=";
  };
}
