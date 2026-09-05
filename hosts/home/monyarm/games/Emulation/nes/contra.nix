{
  config,
  lib,
  pkgs,
  getFile,
  mkRom,
  patchFile,
  fetchRomhacking,
  sources,
  ...
}:
let
  inherit (config.games.emulation) marchive;

  contraEnPatch =
    fetchRomhacking sources.patch.contra |> getFile "Contra Japan (English w NA Title).bps";
  contraClean =
    marchive.contra
    |> getFile "famicom_Contra.nes"
    |> patchFile config.games.emulation.patches.contraRestore;

in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    contra = marchive.contra |> getFile "nes_Contra.nes";
    superC = marchive.contra |> getFile "nes_SuperC.nes";

    # regional variants, registered for enumeration only -- not launchable
    probotectorII = marchive.contra |> getFile "nes_ProbotectorII.nes";
    contraFamicom = marchive.contra |> getFile "famicom_Contra.nes";
    superContraFamicom = marchive.contra |> getFile "famicom_SuperContra.nes";
  };

  games.emulation.patches = {
    contraRestore = ./patches/contra-restoration.bps;
    contraEnglish = contraEnPatch;
  };

  programs.steam.games =
    with config.games.emulation.roms;
    with config.games.emulation.patches;
    {
      CONTRA = mkRom {
        name = "Contra";
        rom = contraClean;
        system = "nes";
        patch = [ contraEnglish ];
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/b9c2922762f9c85424bacb05fdf2899b.ico";
            sha256 = "sha256-II8+w5pO7rXJigoMD87B7ohH490GxkcTChcJMrfkF+8=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/85eb2d1ee93379636956be5b64f554f9.png";
            sha256 = "sha256-7BXW2UZ0CReMjnN5LKtkgriUgt6YU1CTDn4ns8Od8L8=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/0d3ce3290c2d1acf7889ee3420637943.png";
            sha256 = "sha256-iRgrd05aMnupeJMft0ssvmYW1Yvz46vys6Pxfjf9Kns=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/c3f4db3a634aa769c0f1161219272d03.png";
            sha256 = "sha256-gpRbC9aecEl+ge7r3RfDsS2ykKOEEQ37gTa0G6aTyfI=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/f4d3a9b22204bc9cd4a83ec616bf6097.png";
            sha256 = "sha256-8Bkb5eyT0JxrURc02/oOkqZDYked+Bzw19OIKiLEkxY=";
          };
        };
      };
      SUPER_C = mkRom {
        name = "Super C";
        rom = superC;
        system = "nes";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/1d8141959fa95b3c6cf8f7cb1e3d097a.png";
            sha256 = "sha256-DvLrEKhrZj8TwLYaAY6IjrpKIKZml0Sql0zU3t7mUJo=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/e7fec9502eb4a715cff899dc03e6fcff.png";
            sha256 = "sha256-pPY2iEN1ovg9SmZ83t/NWhDO9MALxbc5ldXnRUPmGy4=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/0b40a9328a71074dffa7bd6e36230c68.png";
            sha256 = "sha256-ZoRplpWB+xOyPWcTTMNqxx8kskOayWwjLwlOpkS6kiM=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/9ad4889ab68f967f3858c20a4a596530.png";
            sha256 = "sha256-hv5uYep9MseuJsdJNkQjqOV/9sr/JVp7UdAtgyAo7Mo=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/e5cced85ea75f3fef1ac7fc03f333ee7.png";
            sha256 = "sha256-v0BQbuuJtyyJduJcmStjtAnGp5gVG/BjMSU9PWdlh8c=";
          };
        };
      };
    };
}
