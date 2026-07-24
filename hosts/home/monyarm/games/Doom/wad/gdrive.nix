{
  config,
  getFile,
  fetchGDrive,
  mkDoom,
  ...
}:
{
  games.doom.wads = {
    legendOfDoomBase = fetchGDrive {
      fileId = "120nPbFJY9y0qMF_CSXA3XvutdEp_Gcja";
      sha256 = "sha256-9kPwdCUFlRIxxRfHYIR4v2dJPALHiXHOBj3PrGpSySY=";
      name = "LegendOfDoom.pk3";
    };

    actionDoomRampageEdition =
      fetchGDrive {
        fileId = "115GyqVk6QzG9AeA219AtWlVXul9jiLN7";
        extract = true;
        sha256 = "sha256-9updoVZfYTZ/2XBp62lD3GjlOTC9h7CcVQr4IR1TbME=";
      }
      |> getFile "action.pk3";

    hdoom = fetchGDrive {
      fileId = "197tg35i1tOaFPwg37NY57eFgRQf_6HDJ";
      sha256 = "sha256-gYDzxPwiMZ1T1Kn5jlnQ9Ay6CHLk4JLYVZbNhdAlMq8=";
      name = "HDoom.pk3";
    };
  };

  programs.steam.games = with config.games.doom.wads; {
    LegendOfDoom = mkDoom {
      name = "Legend of Doom";
      iwad = doom2;
      wad = [
        legendOfDoomBase
        legendOfDoomAddon
      ];
    };
    ActionDoomRampageEdition = mkDoom {
      name = "Action Doom: Rampage Edition";
      iwad = doom2;
      wad = [ actionDoomRampageEdition ];
    };
    HDoom = mkDoom {
      name = "HDoom";
      iwad = doom2;
      wad = [ hdoom ];
    };
  };
}
