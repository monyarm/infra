{
  config,
  lib,
  pkgs,
  getFile,
  fetchGDrive,
  mkDoom,
  sources,
  ...
}:
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    legendOfDoomBase = fetchGDrive sources.wad.legendofdoombase;

    actionDoomRampageEdition = fetchGDrive sources.wad.actiondoomrampageedition |> getFile "action.pk3";

    hdoom = fetchGDrive sources.wad.hdoom;
  };

  programs.steam.games = with config.games.doom.wads; {
    LegendOfDoom = mkDoom {
      name = "Legend of Doom";
      iwad = doom2;
      wad = [
        legendOfDoomBase
        legendOfDoomAddon
      ];
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/c2ef3728d9ce090652f36c2e3d4783d0.png";
          sha256 = "sha256-mw8xoxdWzZ4dpXRbxTyslySA4UWCmhxzgoXDMDvXF74=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/7448b674deb2822f61217ceb2806e5a4.png";
          sha256 = "sha256-eJyJIw0Sfr1ov3GXO9CGbuBtFLg9QotFfnirYCyjpUo=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/e382852f04d7d7d131bc0fa2c4cf8cc9.ico";
          sha256 = "sha256-7tqDYJBam7BCyI7nqLvmT7O0Gb91Rxy1CdNAnwSKys0=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/78730126c88500f28e9f26e01e5c53f3.png";
          sha256 = "sha256-b6LBsjMNe4DZfVZQUadA6Oy/HUGhk9cUzgRMLS+tLFQ=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/778ed873531bbeea537c2c6d2bc07d02.png";
          sha256 = "sha256-8nsmR5lHJ4MM2wA4yPj389K6tOsf1wStHUDZ0WapMEw=";
        };
      };
    };
    ActionDoomRampageEdition = mkDoom {
      name = "Action Doom: Rampage Edition";
      iwad = doom2;
      wad = [ actionDoomRampageEdition ];
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/7e56ffc7673521758e669bc7cbfcb3f6.png";
          sha256 = "sha256-aD+kMGLXc7qThcUOZ3zFxHif4rELaKwd0NrHXkr7FMA=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/ba723526105dab1eed97be7998f68a8c.png";
          sha256 = "sha256-Qlg7+lbwNUgalO5kOQVcqPADlcN2aHnrgTZwLmXarP0=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3dc25c5c2413e47ba55f1149a3d179ed.png";
          sha256 = "sha256-pOLzpWRmzeIg2kyZ5CbiIeN43mOTOMUvgxQvIaQxMHE=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/8fe985d8c10160e9186aa6fcd9b40e3e.png";
          sha256 = "sha256-0p6hFfqRVCBhUZ0Jp/muwekq0t2UkqMvFwNPKUmGuig=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/190ba7d0523c4efbb086361025882607.png";
          sha256 = "sha256-pgIPqUAYYK0jnC0kpX/ez3OL9RTnL/K7t7O+nbL3h64=";
        };
      };
    };
    HDoom = mkDoom {
      name = "HDoom";
      iwad = doom2;
      wad = [ hdoom ];
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/7a54486317b6dde9ce8fadaf3e7601f4.png";
          sha256 = "sha256-FmepdMCHp5e5zZmEvmXBMdVjGsfbjoSmRugs0h4ZUzc=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/edc71b273e6d98d3100757f3a52a11f6.png";
          sha256 = "sha256-PBizUyJoDArJBZRjkrMNg9BPf2uYOCtq66d5MG25VOw=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/fd2ae8ec902471d8956fca3486031013.ico";
          sha256 = "sha256-CvzEBLDD7qijb+K4++lrG5dL6a3u7KT0ipr7GKUGESw=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/db346ccb62d491029b590bbbf0f5c412.png";
          sha256 = "sha256-D6lUioprnLn5P0ZYVsI3NmrBruwdPfja533z7jccBiA=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/87c89bd9bf65f0b97330b415d2619499.png";
          sha256 = "sha256-zsjcd9j80F8+Od+JJ5xjgfmGTAj++VSLFQ1JQ1hTG4g=";
        };
      };
    };
  };
}
