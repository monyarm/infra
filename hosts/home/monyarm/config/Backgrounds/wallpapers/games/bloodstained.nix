{
  pkgs,
  fetchSteamCards,
  ...
}:
{
  bloodstained01 = pkgs.fetchurl {
    name = "Bloodstained_Castle.webp";
    url = "https://static.wikia.nocookie.net/ritualofthenight/images/5/58/Bloodstained_Castle.png";
    sha256 = "1p3mbb8aj4ahkiwryzsrg88gfl1zjn9l46dxg3jc222cnmhgl7vn";
  };

  bloodstained02 = pkgs.fetchurl {
    name = "Bloodstained_wallpaper.webp";
    url = "https://static.wikia.nocookie.net/ritualofthenight/images/3/32/Bloodstained_Wallpaper.png";
    sha256 = "0ad5n1q10rd71hcj95zxx1nmrds3ndkl4cgrdwm6ic3nwlkd3w5f";
  };

  bloodstained03 = pkgs.fetchurl {
    name = "Bathin_Boss_revenge_victory.webp";
    url = "https://static.wikia.nocookie.net/ritualofthenight/images/4/4d/Bathin_Boss_Revenge_victory.jpg";
    sha256 = "0sf3m6xxh3c5pkcanv3yirjzn9c9c03y3cfbmb79hr9b9lspimji";
  };

  bloodstainedCurseOfTheMoon = fetchSteamCards {
    appId = 838310;
    cardNames = [
      "curseOfTheMoon"
      "gebel"
      "alfred"
      "heroes"
      "zangetsu"
      "miriam"
    ];
    sha256 = "sha256-yNt2qhZzKnrHrmrI+xBuGoO9Gga6B/6qf9p8NHUqR/k=";
  };

  bloodstainedCurseOfTheMoon2 = fetchSteamCards {
    appId = 1257360;
    cardNames = [
      "gebel"
      "alfred"
      "zangetsu"
      "robert"
      "dominique"
      "boss"
      "coverArt"
      "hachi"
      "miriam"
    ];
    sha256 = "sha256-GagJh1Z2sJcu5T/kSmZdDW2vTbZkD9z7Dm1FFC7d3uk=";
  };
}
