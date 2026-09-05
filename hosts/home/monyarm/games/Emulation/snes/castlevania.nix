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
    draculaX = marchive.castlevaniaAdvance |> getFile "CastlevaniaDraculaX_0409.SFC";
    # "_fake_rom" is MArchiveBatchTool's own naming, not dummy data -- valid
    # SNES header/size, just a different revision than the No-Intro dump.
    superCastlevaniaIv =
      marchive.castlevaniaAnniversary |> getFile "snes_01_supercastlevania4_fake_rom.smc";

    # regional variants, registered for enumeration only -- not launchable
    draculaXAkumajou = marchive.castlevaniaAdvance |> getFile "AkumajouDraculaXX_0408.SFC";
    draculaXVampiresKiss = marchive.castlevaniaAdvance |> getFile "CastlevaniaVampiresKiss_0409.SFC";
    castlevania1Sufami = marchive.castlevaniaAnniversary |> getFile "sufami_01_AkumajouDracula.smc";
  };

  programs.steam.games = with config.games.emulation.roms; {
    DRACULA_X = mkRom {
      name = "Castlevania: Dracula X";
      rom = draculaX;
      system = "snes";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/e81f1e4fe5b85be7a6619d0b33427e01.png";
        sha256 = "sha256-THMff3GC1fEKODycm1ITiVqOhz6hgH+8pprkRtXWF98=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/c3ddc652121ed52263209f0e97b3c7b0.png";
        sha256 = "sha256-ZwoZEYmNLDDsyb3yOoHN0OjGhKX/re1zAkCLaUJhdJU=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/498bce62bd2bda584246701fa0166482.png";
        sha256 = "sha256-L+BFbFriV0J7D5GxxqC+EXFDpqKHRZFyyrKBP9rpoCY=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/9e69af6c3c1ceeff3c2dced65ed63eee.png";
        sha256 = "sha256-ZA6DlrrQ7bwyDpas3Ly6qC3t2+x6E59DxecO+926oAo=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/7919939e64bfe012b032a22b851612a0.png";
        sha256 = "sha256-DHmjUzBQzGSU36N4XoyMqQDd8+0Nc6OhQQrRdBK0048=";
      };
    };
    SUPER_CASTLEVANIA_IV = mkRom {
      name = "Super Castlevania IV";
      rom = superCastlevaniaIv;
      system = "snes";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/74382b603df4a14cc8dc4ea375ddbc64.ico";
        sha256 = "sha256-MC5MLQDvqq35FkJ3PiguH8dczCO1EK5EZPTvK7OJpqM=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/889198b37574d509349c9f98bf44981f.png";
        sha256 = "sha256-BuZWYGUnK2VFyS7N4jZW1hnPOE8kqNjauGeGP8MrQik=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/06277c373fd4be8ecb96de3776dd0963.png";
        sha256 = "sha256-iMNieXgyiG2qzADN/bCLFtenhkSh4wuGUX8oW4qMV0g=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/ae22c9a5b68c3715d9c91444facc4e70.png";
        sha256 = "sha256-hHDfx1BSpNsPRO1DHUqczjYiRHUyOIdGMvuJ+FrwH6g=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/8383f931b0cefcc631f070480ef340e1.png";
        sha256 = "sha256-iUgDMO90OPpZrbv9TECT/srkVSrYoYCfMfER2Xx1bWo=";
      };
    };
  };
}
