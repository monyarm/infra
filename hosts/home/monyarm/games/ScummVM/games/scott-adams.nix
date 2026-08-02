{ pkgs, config, lib, ... }:
let
  # msadams.com itself only offers multi-platform bundles (Windows/Palm/
  # TI-calculator); this ifarchive zip is the actual per-game .dat bundle
  # ScummVM's glk engine expects, and is the one source shared by every
  # Adventure International/Marvel game below.
  adamsGames = pkgs.fetchzip {
    url = "https://www.ifarchive.org/if-archive/scott-adams/games/scottfree/AdamsGames.zip";
    stripRoot = false;
    hash = "sha256-e/uvJ5HAK1XubldExzo11/lfOhJG8EKQWIsEAGJLaw8=";
  };

  mkAdventureInternationalGame = args: {
    engineid = "glk";
    guioptions = "sndNoSubs sndNoMusic";
    path = "${adamsGames}";
  } // args;

  mkSavageIslandGame = version: mkAdventureInternationalGame {
    gameid = "savageisland${toString version}";
    filename = "adv${toString (10 + version - 1)}.dat";
    description = "Savage Island, Part ${toString version}";
  };

  mkMarvelAdventureGame = version: mkAdventureInternationalGame {
    gameid = "marveladventure${if version == 1 then "" else toString version}";
    filename = "quest${toString version}.dat";
    description = "Marvel Adventure #${toString version}";
  };
in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games = {
    adventureland = mkAdventureInternationalGame {
      categoryId = "adventureland_1";
      gameid = "adventureland";
      filename = "adv01.dat";
      description = "Adventureland";
    };
    buckaroobanzai = mkAdventureInternationalGame {
      gameid = "buckaroobanzai";
      filename = "adv14b.dat";
      description = "Buckaroo Banzai";
    };
    claymorguesorcerer = mkAdventureInternationalGame {
      gameid = "claymorguesorcerer";
      filename = "adv13.dat";
      description = "Sorcerer of Claymorgue Castle";
    };
    ghosttown = mkAdventureInternationalGame {
      gameid = "ghosttown";
      filename = "adv09.dat";
      description = "Ghost Town";
    };
    goldenvoyage = mkAdventureInternationalGame {
      gameid = "goldenvoyage";
      filename = "adv12.dat";
      description = "The Golden Voyage";
    };
    marveladventure1 = mkMarvelAdventureGame 1;
    marveladventure2 = mkMarvelAdventureGame 2;
    missionimpossible = mkAdventureInternationalGame {
      gameid = "missionimpossible";
      filename = "adv03.dat";
      description = "Mission Impossible";
    };
    mysteryfunhouse = mkAdventureInternationalGame {
      gameid = "mysteryfunhouse";
      filename = "adv07.dat";
      description = "Mystery Fun House";
    };
    pirateadventure = mkAdventureInternationalGame {
      gameid = "pirateadventure";
      filename = "adv02.dat";
      description = "Pirate Adventure";
    };
    pirateisle = mkAdventureInternationalGame {
      gameid = "pirateisle";
      filename = "adv14a.dat";
      description = "Return to Pirate Isle";
    };
    pyramidofdoom = mkAdventureInternationalGame {
      gameid = "pyramidofdoom";
      filename = "adv08.dat";
      description = "Pyramid Of Doom";
    };
    savageisland1 = mkSavageIslandGame 1;
    savageisland2 = mkSavageIslandGame 2;
    scottsampler = mkAdventureInternationalGame {
      gameid = "scottsampler";
      filename = "sampler1.dat";
      description = "Adventure International's Mini-Adventure Sampler";
    };
    strangeodyssey = mkAdventureInternationalGame {
      gameid = "strangeodyssey";
      filename = "adv06.dat";
      description = "Strange Odyssey";
    };
    thecount = mkAdventureInternationalGame {
      gameid = "thecount";
      filename = "adv05.dat";
      description = "The Count";
    };
    voodoocastle = mkAdventureInternationalGame {
      gameid = "voodoocastle";
      filename = "adv04.dat";
      description = "Voodoo Castle";
    };
  };
}
