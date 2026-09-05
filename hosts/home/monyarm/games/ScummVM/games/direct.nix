{
  pkgs,
  config,
  lib,
  compressScummvmGame,
  getFiles,
  ...
}:
let
  draci =
    pkgs.fetchzip {
      url = "http://www.ucw.cz/draci-historie/binary/dh-en-2012.zip";
      stripRoot = false;
      hash = "sha256-h1dIiMk/11dt5A0YwZkYBIWENBvD81fYdTs8/xatzNI=";
    }
    |> compressScummvmGame "draci";

  hugo1 =
    pkgs.fetchzip {
      url = "https://archive.org/download/hugos_house_of_horrors_12s/hugo1.zip";
      stripRoot = false;
      hash = "sha256-9t1ipZf91FO8cjZYe7WNOz/SCGp1m53/yK/iaLJd0vY=";
    }
    |> compressScummvmGame "hugo";

  msn1 =
    pkgs.fetchzip {
      url = "https://familie-dingel.de/simplicity/msn/msn.zip";
      hash = "sha256-kqKv3Bt0y8C0NDIDWlj2JX2bU+kUXAN+4vYAY+5GSSo=";
    }
    |> compressScummvmGame "supernova";

  msn2 =
    pkgs.fetchzip {
      url = "https://familie-dingel.de/simplicity/msn/ms2.zip";
      hash = "sha256-+TDzndnUc5JAMWCbjZMMNpVediDajEP1LbC2JXuk/JI=";
    }
    |> compressScummvmGame "supernova";

  softporn =
    pkgs.fetchzip {
      url = "https://www.ifarchive.org/if-archive/games/zcode/softporn.zip";
      stripRoot = false;
      hash = "sha256-yKnQ0UjstfO32T0s41+0dAeKyg4oIPsripSFJtkIx8I=";
    }
    |> compressScummvmGame "glk";

  brokenSword25 =
    pkgs.fetchzip {
      url = "https://downloads.scummvm.org/frs/extras/Broken%20Sword%202.5/sword25-v1.0.zip";
      stripRoot = false;
      hash = "sha256-7SR16QdZ6KGnlYFGhCoLmNHLLwmHm5IEwPzMAStRDD0=";
    }
    |> getFiles [ "data.b25c" ]
    |> compressScummvmGame "sword25";

  drasculaBase = pkgs.fetchzip {
    url = "https://downloads.scummvm.org/frs/extras/Drascula_%20The%20Vampire%20Strikes%20Back/drascula-1.0.zip";
    stripRoot = false;
    hash = "sha256-mJKcCMBlBtpt4vqsINsg7a85Jx3KJ4EcYDT5kh/cY0U=";
  };

  drasculaAudio = pkgs.fetchzip {
    url = "https://downloads.scummvm.org/frs/extras/Drascula_%20The%20Vampire%20Strikes%20Back/drascula-audio-2.0.zip";
    stripRoot = false;
    hash = "sha256-cOsR0URpb5CX3bFP1dr60N+vU2M2Pz/dwyy0MzGK6v4=";
  };

  drascula =
    pkgs.runCommand "drascula-with-audio"
      {
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        cp -Rs ${drasculaBase}/. $out/
        cp -Rs ${drasculaAudio}/audio $out/
      ''
    |> compressScummvmGame "drascula";

  dreamweb =
    pkgs.fetchzip {
      url = "https://downloads.scummvm.org/frs/extras/Dreamweb/dreamweb-cd-uk-1.1.zip";
      stripRoot = false;
      hash = "sha256-zUYqiEUCgS6II1DCxz7eeAJHDqeohqOeCl40BP8z4hE=";
    }
    |> compressScummvmGame "dreamweb";

  griffonLegend =
    pkgs.fetchzip {
      url = "https://downloads.scummvm.org/frs/extras/Griffon%20Legend/griffon-1.0.zip";
      stripRoot = false;
      hash = "sha256-zqPEp5eIDJ8GezQpcJWi0jlpnOXnj/hqhyvzuz7gKm8=";
    }
    |> compressScummvmGame "griffon";

  sfinx =
    pkgs.fetchzip {
      url = "https://downloads.scummvm.org/frs/extras/Sfinx/sfinx-en-v1.1.zip";
      hash = "sha256-FvrkFI3GFTV14Gl1xInqQ4zag2V6XkWakd2uthNJLdE=";
    }
    |> compressScummvmGame "cge2";

  soltys =
    pkgs.fetchzip {
      url = "https://downloads.scummvm.org/frs/extras/Soltys/soltys-en-v1.0.zip";
      stripRoot = false;
      hash = "sha256-hYMfIGXlRE4sIplw0gcFnjGNNwIl6rpNzlwrlONshzM=";
    }
    |> compressScummvmGame "cge";

  nipponSafes =
    pkgs.fetchzip {
      url = "https://downloads.scummvm.org/frs/extras/Nippon%20Safes/nippon-1.0.zip";
      stripRoot = false;
      hash = "sha256-yCWDh3dkg/Q3z8+1RuxfgKNBlFh1LPqoG7cbPgdjV3A=";
    }
    |> compressScummvmGame "parallaction";

  mysteryHouse =
    pkgs.fetchzip {
      url = "https://downloads.scummvm.org/frs/extras/Mystery%20House/MYSTHOUS.zip";
      stripRoot = false;
      hash = "sha256-RTSPHfduu/QbzNVo1pq4eRquFEcoQjVYFyf1VDRRh3Q=";
    }
    |> compressScummvmGame "adl";

in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games = {
    draci = {
      engineid = "draci";
      description = "Draci Historie";
      path = "${draci}";
      images = {
        wide = "${./art/wide/draci.jpg}";
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/62d45163a5d8df6a70f41cda80b6eaf3.png";
          sha256 = "sha256-akqmBoS0gugPNv3ZVApQuAQ469mJiwPK2HcNIn8oH+A=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/c16ef122f714c34ba925fedc08296f09.jpg";
          sha256 = "sha256-8YhIF0zsCPRHhR9E8jfSiFxMCQBE4dXmbIhau36LBJg=";
        };
      };
    };

    hugo1 = {
      gameid = "hugo1";
      engineid = "hugo";
      description = "Hugo 1: Hugo's House of Horrors";
      path = "${hugo1}";
      images = {
        wide = "${./art/wide/hugo1.png}";
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/87ebf51eb7c27e5408bf64af37d67b21.png";
          sha256 = "sha256-Ven4wy4wuyBOxzb1FJHtFsGfzIcTwWmGCq9o/fSN9tM=";
        };
      };
    };

    msn1 = {
      categoryId = "msn1";
      engineid = "supernova";
      guioptions = "sndNoMIDI gameOption1 gameOption2";
      description = "Mission Supernova 1";
      improved = true;
      tts_enabled = false;
      path = "${msn1}";
      images.wide = "${./art/wide/missionsupernova.png}";
    };

    msn2 = {
      categoryId = "msn2";
      engineid = "supernova";
      guioptions = "sndNoMIDI gameOption1 gameOption2";
      description = "Mission Supernova 2";
      improved = true;
      tts_enabled = false;
      path = "${msn2}";
      images.wide = "${./art/wide/missionsupernova.png}";
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
      images = {
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/073898f2c646f60aa4812d79861f44c0.png";
          sha256 = "sha256-3qhX+GhMntwCN79geabiO/7A01wD14goOUAkUT0yy4k=";
        };
        wide = "${./art/wide/softporn.png}";
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/bceb3255d9e971801589ea08667466f0.png";
          sha256 = "sha256-OVPJM+csAMpnuyjHMJDqwJrlNPy7Wp4Y8oswNmTGN94=";
        };
      };
    };

    brokenSword25 = {
      engineid = "sword25";
      english_speech = true;
      guioptions = "sndNoMIDI noAspect gameOption1";
      description = "Broken Sword 2.5";
      path = "${brokenSword25}";
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/31d45a741449781faf6d87f8bf42df9a.png";
          sha256 = "sha256-LBSinIn1mw3qff9307HDSuxCu0dT0BEiuu0AQpsLtOw=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/18f48bca9f603fd749dc99ab7fa48ff5.png";
          sha256 = "sha256-xSPpbVlVZYKIfVstSDmFi86XesaH/qvnYOURTkmphGo=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/a90dfb90a3b8877714dd8f0caa756ec6.png";
          sha256 = "sha256-yTPDUvlGWnZHvntjci3bawkNSEoIT5TCq34oQ+fFyIM=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/5d78874deb55feb4820dd9421411b3d1.ico";
          sha256 = "sha256-AdOIWh9T+C/XgQ/iFABuMW/uIRPatsIHAaHxXedwTKE=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/ae3559127a0eda3885a7eaff3dba3297.png";
          sha256 = "sha256-RL2v8vCCGLXhncv227r+yY5ggYbbmcnoQYbT84PE24s=";
        };
      };
    };

    drascula = {
      engineid = "drascula";
      originalsaveload = true;
      guioptions = "sndNoMIDI sndLinkSpeechToSfx gameOption1";
      description = "Drascula: The Vampire Strikes Back";
      path = "${drascula}";
      images = {
        wide = "${./art/wide/drascula.jpg}";
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/c2385a5e739790f3b8c1d459abee3e5b.jpg";
          sha256 = "sha256-BrwGLHSqYGyhgoa2CakG2kdNjISFa320zlethJV+SfM=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/6c159cf6cb6cd27195007120b8f2578e.jpg";
          sha256 = "sha256-Xa4TEAKrL2WVCAz4Ln2YynhSJzgoAhquMZ21JmNJTjg=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/3b155e7975caedac55e57c64b23d2843.ico";
          sha256 = "sha256-eIc74v0gqLohT8+fCGjVWjkyya3Emb2Loyy024PB/vQ=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/e335b7276aee3087b73ebfa5e3193655.png";
          sha256 = "sha256-gB0Mkq7uAuShRo8qru3SFogVoIxd+RtspfQaDxmIrbY=";
        };
      };
    };

    dreamweb = {
      gameid = "dreamweb_cd";
      extra = "CD";
      engineid = "dreamweb";
      tts_enabled_speech = false;
      originalsaveload = true;
      tts_enabled_objects = false;
      guioptions = "sndNoMIDI gameOption1 gameOption2";
      bright_palette = true;
      description = "DreamWeb";
      path = "${dreamweb}";
      images = {
        wide = "${./art/wide/dreamweb.png}";
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/f60c1886f4c0b55caab4f18ae7c4bbcf.jpg";
          sha256 = "sha256-m4ld4k8bTQs/pe7X2bOrOm1YXGj1nJoLPROVtOYQciM=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3827b1b153da15842724a9a3dd558767.jpg";
          sha256 = "sha256-B5J6LTMMxM8dMsBoS4ESzeaR9ZLaKVfVqBPpIUzysBs=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/e90f24cff5f0c12e4041b8e3eaa3a623.ico";
          sha256 = "sha256-HkKPhRpKhK3euAayB0Kiji1jiO9QFTPnMT/As9zqBmE=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/0ea23eed0a4248a38bdfae00b75e960a.png";
          sha256 = "sha256-f3qAorFFNJVB3xIGozhQkMmLa1GPmbqe6E7Aj5xXtWU=";
        };
      };
    };

    griffon = {
      engineid = "griffon";
      platform = "windows";
      guioptions = "sndNoMIDI gameOption1";
      description = "The Griffon Legend";
      tts_enabled = false;
      path = "${griffonLegend}";
      images.wide = "${./art/wide/griffon.jpg}";
    };

    sfinx = {
      gameid = "sfinx";
      engineid = "cge2";
      extra = "Freeware v1.1";
      tts_enabled_speech = false;
      tts_enabled_objects = false;
      guioptions = "gameOption1 gameOption2 gameOption3";
      description = "Sfinx";
      enable_color_blind = false;
      path = "${sfinx}";
      images.wide = "${./art/wide/sfinx.png}";
    };

    soltys = {
      engineid = "cge";
      extra = "Freeware v1.0";
      guioptions = "gameOption1 gameOption2";
      description = "Soltys";
      path = "${soltys}";
      images = {
        wide = "${./art/wide/soltys.png}";
        grid = "${./art/grid/soltys.jpg}";
      };
    };

    nipponSafes = {
      engineid = "parallaction";
      extra = "Multi-lingual";
      guioptions = "sndNoSpeech launchNoLoad";
      description = "Nippon Safes Inc.";
      language = "";
      path = "${nipponSafes}";
      images = {
        wide = "${./art/wide/nipponsafes.png}";
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/ba6341e5d03dd014c894019a7f235877.jpg";
          sha256 = "sha256-BaVMeG2WEHQkP/T+9DeWQhIuwO3owt5YI9aLhn4vYxg=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/ad85e09484d8c68e5ad781a9c82efdee.png";
          sha256 = "sha256-iJTSCONnoyBi59iFyaWXtgJo3wB4CLQh+2hzjdEmFKU=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/c0b47ad5d111557c967519167418e33b.png";
          sha256 = "sha256-Mmmf2KsCJbGntCP20/IqyvL/Av/Mo8+92fjxJ4C5caE=";
        };
      };
    };

    mysteryHouse = {
      categoryId = "hires1_apple2";
      gameid = "hires1";
      engineid = "adl";
      extra = "Public Domain";
      color = true;
      platform = "apple2";
      scanlines = false;
      monotext = true;
      guioptions = "sndNoMIDI gameOption1 gameOption2 gameOption4 gameOption5";
      description = "Hi-Res Adventure #1: Mystery House";
      ntsc = true;
      path = "${mysteryHouse}";
      images = {
        wide = "${./art/wide/mysteryhouse.jpg}";
        grid = "${./art/grid/mysteryhouse.jpg}";
      };
    };
  };
}
