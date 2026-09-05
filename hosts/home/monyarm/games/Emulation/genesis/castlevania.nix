{
  config,
  lib,
  pkgs,
  getFile,
  mkRom,
  ...
}:
let
  inherit (config.games.emulation) marchive;
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    castlevaniaBloodlines =
      marchive.castlevaniaAnniversary |> getFile "sega_us_CastlevaniaBloodlines.bin";

    # regional variants, registered for enumeration only -- not launchable
    vampireKillerJp = marchive.castlevaniaAnniversary |> getFile "sega_jp_VampireKiller.bin";
  };

  programs.steam.games = with config.games.emulation.roms; {
    CASTLEVANIA_BLOODLINES = mkRom {
      name = "Castlevania: Bloodlines";
      rom = castlevaniaBloodlines;
      system = "genesis";
      images = {
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/8d518efb0d0c9dcfc08b0b18ad8a93a5.png";
          sha256 = "sha256-9ntIz6R9KAIET4PWSUDLGrNZ2RXzVYxDe+98x5IhPmg=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/7dec083c36a00885da853950beeb05ea.png";
          sha256 = "sha256-f7jeeVmJ5DsVEXBQtw8DuzdZZwNCEMvOOMdwxBVFQuo=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/e9f4bcf9d56d5602c41b7ec6ab371bdc.png";
          sha256 = "sha256-y/shQ6ric1q1ZXX5Pb91Zv30zoSBTEjJbqUNowZLdNs=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/498b92b465f407b93e2cd25f9cc5b97f.png";
          sha256 = "sha256-mt6cN2xOLsjPvi4nHeNoRsWzejtV4lTjCoQMhapJo/c=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/cfe12d07973eb647d2ba40f76257ce1a.png";
          sha256 = "sha256-KQ4s4sdfEW3EacHAB0Xpg9465vRCbCiCgmhoDPWAig4=";
        };
      };
    };
  };
}
