{ pkgs, fetchSteamCards, ... }:
{
  bloodstained01 = pkgs.fetchurl {
    url = "https://static.wikia.nocookie.net/ritualofthenight/images/5/58/Bloodstained_Castle.png";
    sha256 = "1p3mbb8aj4ahkiwryzsrg88gfl1zjn9l46dxg3jc222cnmhgl7vn";
  };

  bloodstained02 = pkgs.fetchurl {
    url = "https://static.wikia.nocookie.net/ritualofthenight/images/3/32/Bloodstained_Wallpaper.png";
    sha256 = "0ad5n1q10rd71hcj95zxx1nmrds3ndkl4cgrdwm6ic3nwlkd3w5f";
  };

  bloodstained03 = pkgs.fetchurl {
    url = "https://static.wikia.nocookie.net/ritualofthenight/images/4/4d/Bathin_Boss_Revenge_victory.jpg";
    sha256 = "0sf3m6xxh3c5pkcanv3yirjzn9c9c03y3cfbmb79hr9b9lspimji";
  };

  bloodstainedCurseOfTheMoon = fetchSteamCards {
    appId = 838310;
    hash = "sha256-zNnJPXe8HdTES0JbsHg4b8ynHeAu63HkYP+jzYt4Xdo=";
  };
}
