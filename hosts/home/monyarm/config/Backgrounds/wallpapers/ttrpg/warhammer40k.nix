{
  fetchSteamCards,
  fetchSteam,
  splitFiles,
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
  warhammer40kGladiusWallpapers =
    let
      files = [
        "Wallpapers/W40K_Gladius-wallpapers-1920x1080/W40K_Gladius-wallpapers-1920x1080_1.jpg"
        "Wallpapers/W40K_Gladius-wallpapers-1920x1080/W40K_Gladius-wallpapers-1920x1080_2.jpg"
        "Wallpapers/W40K_Gladius-wallpapers-1920x1080/W40K_Gladius-wallpapers-1920x1080_3.jpg"
        "Wallpapers/W40K_Gladius-wallpapers-1920x1080/W40K_Gladius-wallpapers-1920x1080_4.jpg"
        "Wallpapers/W40K_Gladius-wallpapers-1920x1080/W40K_Gladius-wallpapers-1920x1080_5.jpg"
        "Wallpapers/W40K_Gladius-wallpapers-1920x1080/W40K_Gladius-wallpapers-1920x1080_6.jpg"
        "Wallpapers/W40K_Gladius-wallpapers-1920x1080/W40K_Gladius-wallpapers-1920x1080_7.jpg"
      ];
    in
    fetchSteam {
      appId = 489630;
      depotId = 870550;
      manifestId = 7813621408118342533;
      sha256 = "sha256-W7SIhjt7CqgW4jeBPByp2jjGhzlIToarTavMECt+iI0=";
      filelist = files;
    }
    |> splitFiles files;
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
