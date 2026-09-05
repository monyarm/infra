{
  config,
  lib,
  pkgs,
  getFile,
  fetchItch,
  mkDoom,
  findWad,
  sources,
  ...
}:
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    simpsons3Doom = fetchItch sources.wad.simpsons3doom |> getFile "Simpsons3Ddoomrecreation.pk3";
    venturous = fetchItch sources.wad.venturous |> getFile (findWad sources.wad.venturous.files);
    square = fetchItch sources.wad.square |> getFile "square1.pk3";
    bikiniBottomMassacre =
      fetchItch sources.wad.bikinibottommassacre |> getFile "bikini bottom massacre.wad";
  };

  programs.steam.games = with config.games.doom.wads; {
    Simpsons3Doom = mkDoom {
      name = "The Simpsons: Bart Saves Springfield";
      iwad = doom2;
      wad = [ simpsons3Doom ];
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/16ee24f2b79f949dfde2b677aad26d8e.png";
        sha256 = "sha256-61qbO1PLyMETUSs6pdfQbeAyT/2yzsjUY/zYt8DiN2g=";
      };
    };
    Venturous = mkDoom {
      name = "Venturous";
      iwad = doom2;
      wad = [ venturous ];
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/425ba29ab2a548d184d34c83d7fee2bc.jpg";
        sha256 = "sha256-WTMlKhzK0wLZSw1XWYhihhoRDRhRe7jzvIewG32gP9E=";
      };
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/75d447ff881e7a5e48b43fe0ca091ae5.ico";
        sha256 = "sha256-vAZtNPbbP7mAjHRfUTtg0jTzzfzCnOkNYp26TwW6wVM=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/aa4e5f408c3a04a5c645800cdd25e4e8.png";
        sha256 = "sha256-J0yohnp7aUI/wymKt7/2SykLv3ItyZJyOtrvXvCZU/E=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/14709e35a55a35152a732a2f22d110c1.png";
        sha256 = "sha256-buCKYgIOK5Ak32/NHK7esiA0j25FyhDaGEoyRMJoD10=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/edbf85593c5a70a692a648048c12dd68.png";
        sha256 = "sha256-9B+hlJ48/v2Q/ZURgarrGS/EPF3DEZUuvJpWyMxCw8U=";
      };
    };
    AdventuresOfSquare = mkDoom {
      name = "The Adventures of Square";
      iwad = square;
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/5e4c4233882f7f4ddb6e14d961f31b03.png";
          sha256 = "sha256-owyKcIe4rQGu8PkYTQyzZScOx0oPIaWL2iiD0ef164Q=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/68cd2b8a81bbd3392dd4db60d4c3f06e.png";
          sha256 = "sha256-/dRC1WhYFHHRljniZYlM1xHttrggExm7sc+ZaC4JXPE=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/508087c9dd886b6a1a82cb805c2ee328.png";
          sha256 = "sha256-IWyGVVU3xEtvluDtkQCy95BmDM/0ZqFX/nKpJRJHAcc=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/9a6a1aaafe73c572b7374828b03a1881.png";
          sha256 = "sha256-k5ZM0XOLIClBb7Mlc4A6bZW9NARrrxIfS+YIxLaZWXg=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/dffa23e3f38973de8a5a2bce627e261b.png";
          sha256 = "sha256-H1CE5vXfo3W3BDkEtJl2hoMLmuR4qXed7yuYg07dNV8=";
        };
      };
    };
    BikiniBottomMassacre = mkDoom {
      name = "The Bikini Bottom Massacre";
      iwad = doom2;
      wad = [ bikiniBottomMassacre ];
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/495ea32c5ccf99ff8d2417ccff639f09.png";
        sha256 = "sha256-J9vV61HbxFhE+tEldBZJcl3psRuNurB2peplW/qiSL0=";
      };
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/fb08818732dc3942a4423f03f19a9cd0.ico";
        sha256 = "sha256-/M9wIJfEu9+NpCJt8LEhVly8qWsyHIzJoh9Zxf6i9/c=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/991f0146bb5e7fe3cc5380ce3dfabe5a.png";
        sha256 = "sha256-CPerMaV7fVHcWDyHeY6AewqP0lp1aJ4Ws+LvwgAzrCo=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/e9bb90779ba2ce18b27c044fb139b879.png";
        sha256 = "sha256-x3DZKgv0G2yPfm+09MDq+/oFgB2kyTvy5SxMzQqdSSU=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/43b139a66de358dc30d8e9ceaa3a2e9b.png";
        sha256 = "sha256-C/h4GrOySBdY6ohpNDEoiwVlxZFXEcOzCPaCMUct3/0=";
      };
    };
  };
}
