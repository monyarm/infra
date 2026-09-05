{
  pkgs,
  config,
  lib,
  compressScummvmGame,
  ...
}:
let
  mkGlkCommonGame =
    args:
    {
      engineid = "glk";
      speak = false;
      speak_input = false;
      guioptions = "sndNoSubs sndNoMusic";
      filename = "G0";
    }
    // args;

  transylvania =
    pkgs.fetchzip {
      url = "http://graphicsmagician.com/polarware/download/adventures/TransylvaniaPC.zip";
      stripRoot = false;
      hash = "sha256-9ZrGpVS/S8V0TdOKy3p6U9I3lpYYQs7Lz/tHLH02dzQ=";
    }
    |> compressScummvmGame "glk";
  transylvaniaV2 =
    pkgs.fetchzip {
      # graphicsmagician.com/polarware/comprehend.htm's own history section says
      # Transylvania's original (pre-Comprehend, "Graphics Magician" engine)
      # release isn't the ScummVM-compatible one -- it was "also re-released in
      # a new Comprehend edition" for PC, and that's the only Comprehend-format
      # PC download the page offers. ScummVM's separate transylvania/
      # transylvaniav2 detection targets both point at this single release.
      url = "http://graphicsmagician.com/polarware/download/adventures/TransylvaniaPC.zip";
      stripRoot = false;
      hash = "sha256-9ZrGpVS/S8V0TdOKy3p6U9I3lpYYQs7Lz/tHLH02dzQ=";
    }
    |> compressScummvmGame "glk";
  crimsonCrown =
    pkgs.fetchzip {
      url = "http://graphicsmagician.com/polarware/download/adventures/CrimsonCrownPC.zip";
      stripRoot = false;
      hash = "sha256-IiJMXPZ02Iyrz7wGKfm+pizZJPf/f2t1Gp70fPjNTXw=";
    }
    |> compressScummvmGame "glk";
  ooTopos =
    pkgs.fetchzip {
      url = "http://graphicsmagician.com/polarware/download/adventures/OoToposPC.zip";
      stripRoot = false;
      hash = "sha256-QeR0lPjPZmxZk1lYE48nmIdmpecHAK1ybQJYkC79GyA=";
    }
    |> compressScummvmGame "glk";
  talisman =
    pkgs.fetchzip {
      url = "http://graphicsmagician.com/polarware/download/adventures/TalismanPC.zip";
      stripRoot = false;
      hash = "sha256-tolVRu6aeIaBj2u8vSMw2tkoDUBa0C7dbFvz4pByInA=";
    }
    |> compressScummvmGame "glk";
in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games = {
    transylvania = mkGlkCommonGame {
      gameid = "transylvania";
      description = "Transylvania";
      path = "${transylvania}";
      images.wide = "${./art/wide/transylvania.jpg}";
    };

    transylvaniaV2 = mkGlkCommonGame {
      gameid = "transylvaniav2";
      description = "Transylvania (V2)";
      path = "${transylvaniaV2}";
      # Same game, same art -- reuse transylvania's images wholesale instead
      # of duplicating individual fields (same idiom as ScummVM/games/steam.nix's
      # maniacMansionV1/V2).
      images = config.programs.steam.games.transylvania.images;
    };

    ootopos = mkGlkCommonGame {
      gameid = "ootopos";
      description = "OO-Topos";
      path = "${ooTopos}";
      images.wide = "${./art/wide/ootopos.png}";
    };

    crimsoncrown = mkGlkCommonGame {
      gameid = "crimsoncrown";
      filename = "CC1.GDA";
      description = "Crimson Crown";
      path = "${crimsonCrown}";
      images.wide = "${./art/wide/crimsoncrown.png}";
    };

    talisman = mkGlkCommonGame {
      gameid = "talisman";
      description = "Talisman: Challenging the Sands of Time";
      path = "${talisman}";
      images.wide = "${./art/wide/talisman.png}";
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/ac911ec027bb2da79f1bc4639b17fc90.png";
        sha256 = "sha256-lOe43RscapNpig5XPKaT2ctmlKK1VIfTTtXdFBDGzbs=";
      };
    };
  };
}
