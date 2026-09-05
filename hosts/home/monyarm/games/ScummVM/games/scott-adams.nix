{
  pkgs,
  config,
  lib,
  compressScummvmGame,
  ...
}:
let
  # msadams.com itself only offers multi-platform bundles (Windows/Palm/
  # TI-calculator); this ifarchive zip is the actual per-game .dat bundle
  # ScummVM's glk engine expects, and is the one source shared by every
  # Adventure International/Marvel game below.
  adamsGames =
    pkgs.fetchzip {
      url = "https://www.ifarchive.org/if-archive/scott-adams/games/scottfree/AdamsGames.zip";
      stripRoot = false;
      hash = "sha256-e/uvJ5HAK1XubldExzo11/lfOhJG8EKQWIsEAGJLaw8=";
    }
    |> compressScummvmGame "glk";

  mkAdventureInternationalGame =
    args:
    {
      engineid = "glk";
      guioptions = "sndNoSubs sndNoMusic";
      path = "${adamsGames}";
    }
    // args;

  mkSavageIslandGame =
    version:
    mkAdventureInternationalGame {
      gameid = "savageisland${toString version}";
      filename = "adv${toString (10 + version - 1)}.dat";
      description = "Savage Island, Part ${toString version}";
    };

  mkMarvelAdventureGame =
    version:
    mkAdventureInternationalGame {
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
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/8490a6195a00b1a44e8488c7eed7bbc5.png";
        sha256 = "sha256-d8O3RsCQfzeSZsU2YnC0UYaVn7AqVgonBUq0gYOTzVk=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/bfcf0106519bcb8de47d29ddda2c7616.jpg";
        sha256 = "sha256-We7h3N8Xdhp71FXMoG/iuH4UGpocewxk57p+HICVf3A=";
      };
    };
    buckaroobanzai = mkAdventureInternationalGame {
      gameid = "buckaroobanzai";
      filename = "adv14b.dat";
      description = "Buckaroo Banzai";
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/68f838ae0e45cd4995a3dc25fbe3428a.jpg";
        sha256 = "sha256-tw4WIk4i0Hi+fDePAY2PAvV4oXPopjIshBKSMs646wI=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/c85bd019483ea2c17032bf940015d8c6.jpg";
        sha256 = "sha256-uQIvSVNyKhSOfrNo4OlUEGTDWOjRoiovpNAHYKO2Ets=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/e991fdd1385aee014e253a2937aa76f5.png";
        sha256 = "sha256-XIaxhoZEG1UfSTyeLjP8xOJ5jkeWnBeLxYZrmQSyzRw=";
      };
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
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/a424ded436368e3f9f10da14c23acc85.png";
        sha256 = "sha256-rMBV/IJpuw5rlZxFKQhO4d12mSchXZ1A3SQVnp4Ae7w=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/6551516d51364661aed940bde89d0b12.png";
        sha256 = "sha256-mgPhA9IsKiWGLtsYtmhzgTNYsCp/6w0F2KvqpIwUYm0=";
      };
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
