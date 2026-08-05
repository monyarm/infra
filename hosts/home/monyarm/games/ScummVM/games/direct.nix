{
  pkgs,
  config,
  lib,
  ...
}:
let
  draci = pkgs.fetchzip {
    url = "http://www.ucw.cz/draci-historie/binary/dh-en-2012.zip";
    stripRoot = false;
    hash = "sha256-h1dIiMk/11dt5A0YwZkYBIWENBvD81fYdTs8/xatzNI=";
  };

  hugo1 = pkgs.fetchzip {
    url = "https://archive.org/download/hugos_house_of_horrors_12s/hugo1.zip";
    stripRoot = false;
    hash = "sha256-9t1ipZf91FO8cjZYe7WNOz/SCGp1m53/yK/iaLJd0vY=";
  };

  msn1 = pkgs.fetchzip {
    url = "https://familie-dingel.de/simplicity/msn/msn.zip";
    hash = "sha256-kqKv3Bt0y8C0NDIDWlj2JX2bU+kUXAN+4vYAY+5GSSo=";
  };

  msn2 = pkgs.fetchzip {
    url = "https://familie-dingel.de/simplicity/msn/ms2.zip";
    hash = "sha256-+TDzndnUc5JAMWCbjZMMNpVediDajEP1LbC2JXuk/JI=";
  };

  softporn = pkgs.fetchzip {
    url = "https://www.ifarchive.org/if-archive/games/zcode/softporn.zip";
    stripRoot = false;
    hash = "sha256-yKnQ0UjstfO32T0s41+0dAeKyg4oIPsripSFJtkIx8I=";
  };
in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games = {
    draci = {
      engineid = "draci";
      description = "Draci Historie";
      path = "${draci}";
    };

    hugo1 = {
      gameid = "hugo1";
      engineid = "hugo";
      description = "Hugo 1: Hugo's House of Horrors";
      path = "${hugo1}";
    };

    msn1 = {
      categoryId = "msn1";
      engineid = "supernova";
      guioptions = "sndNoMIDI gameOption1 gameOption2";
      description = "Mission Supernova 1";
      improved = true;
      tts_enabled = false;
      path = "${msn1}";
    };

    msn2 = {
      categoryId = "msn2";
      engineid = "supernova";
      guioptions = "sndNoMIDI gameOption1 gameOption2";
      description = "Mission Supernova 2";
      improved = true;
      tts_enabled = false;
      path = "${msn2}";
    };

    softporn = {
      gameid = "softporn";
      engineid = "glk";
      extra = "971018";
      speak = false;
      speak_input = false;
      guioptions = "sndNoSubs sndNoMusic sndNoSFX";
      filename = "softporn.z5";
      description = "Softporn Adventure";
      path = "${softporn}";
    };
  };
}
