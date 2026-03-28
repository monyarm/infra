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
    hash = "sha256-sofSPD/1YOhMy9MctXNYvRdXevShhUlQtnPkW+7L6PM=";
  };
  rogueTraderCRPG = fetchSteamCards {
    appId = 2186680;
    hash = "sha256-FntzZUbQ7YsPQHtiaR8gDiRMPsOFYmOn9k70XoJwISI=";
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
