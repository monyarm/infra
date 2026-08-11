{
  config,
  lib,
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
