{
  config,
  lib,
  fetchGOG,
  pkgs,
  compressScummvmGame,
  getFiles,
  ...
}:
let
  teenagent =
    fetchGOG {
      game = "teenagent";
      fileId = "en1installer0";
      sha256 = "sha256-RzEDcLdSp2gKvWeHAJWdRhPRyzQObrSaX+Bdb9VmU2E=";
    }
    |> compressScummvmGame "teenagent";

  ultima4 =
    fetchGOG {
      game = "ultima_iv_quest_of_the_avatar";
      fileId = "en1installer0";
      sha256 = "sha256-dW2BmATKhtLXTIjJE2aIDpd5wRQ3teICzYsxStCttvo=";
    }
    |> compressScummvmGame "ultima";

  # GOG's installer folder for these has siblings ScummVM never reads
  # (DOSBox, other-language subdirs, installer chrome); narrow to the
  # subdir the game's `path` actually uses before compressScummvmGame walks
  # the tree, instead of after.
  dragonsphere =
    fetchGOG {
      game = "dragonsphere";
      fileId = "en1installer0";
      sha256 = "sha256-vaB3evCzpUuzo5Y1qLcxa2iwTdxplqfEgCdX3PlJqLk=";
    }
    |> getFiles [ "DRAGON" ]
    |> compressScummvmGame "mads";

  martianDreams =
    fetchGOG {
      game = "ultima_worlds_of_adventure_2_martian_dreams";
      fileId = "en1installer0";
      sha256 = "sha256-3YdzHQX0TXvVNXawhd2qoFAbFx+xFI7DAyO6W6jG/DU=";
    }
    |> getFiles [ "MARTIAN" ]
    |> compressScummvmGame "ultima";

  bladeRunner =
    fetchGOG {
      game = "blade_runner";
      fileId = [
        "en1installer0"
        "en1installer1"
      ];
      sha256 = "sha256-ZZUz4TGdl5DB8vDd0eDgzMdXaHbWJ3BpKhGrULj/6+0=";
    }
    |> compressScummvmGame "bladerunner";

  grimFandango =
    fetchGOG {
      game = "grim_fandango_remastered";
      fileId = [
        "en1installer0"
        "en1installer1"
      ];
      sha256 = "sha256-37LX6R7vyYIqIfOZQAh9QCrVNqhI29MGiB1rFouhDsk=";
    }
    # Allow-list built by reading engines/grim/resource.cpp (ResourceLoader
    # ctor's static LAB list, gated on isRemastered()) and localize.cpp --
    # this is the exact and complete set of files ScummVM's grim engine ever
    # opens for this release. Everything else in app/ (GrimFandango.exe,
    # SDL2.dll, Lua.dll, chore.dll, compiled x86 shaders, FontsHD/MoviesHD,
    # DATA006/007.LAB, MATERIALS*.LAB, IMAGESPATCH001.LAB, GOG/Galaxy
    # chrome) belongs to the native remaster engine only.
    |> getFiles [
      "app/CREDITS.LAB"
      "app/DATA00[0-4].LAB"
      "app/MOVIE0[0-4].LAB"
      "app/VOX000[0-4].LAB"
      "app/YEAR[0-5]MUS.LAB"
      "app/commentary.lab"
      "app/IMAGES.LAB"
      "app/grim.??.tab"
      "app/en_gagl088.lip"
    ]
    |> compressScummvmGame "grim";

  # SCI0/SCI01/SCI1.1 (pre-SCI32) games -- compress_sci is safe for these.
  conquestsOfCamelot =
    fetchGOG {
      game = "conquests_of_camelot";
      fileId = "en1installer0";
      sha256 = "sha256-A9Y7GkZKcZLnINWNVEaTHIt+R4/wp+Zbk7lVyvPDY44=";
    }
    |> compressScummvmGame {
      engineid = "sci";
      sciSupported = true;
    };

  conquestsOfTheLongbow =
    fetchGOG {
      game = "conquests_of_the_longbow";
      fileId = "en1installer0";
      sha256 = "sha256-fObJ1tJNMqcsR52VSWJGSCSWZrp1e9LqwZ3QIHmaf1g=";
    }
    |> compressScummvmGame {
      engineid = "sci";
      sciSupported = true;
    };

  returnOfThePhantom =
    fetchGOG {
      game = "return_of_the_phantom";
      fileId = "en1installer0";
      sha256 = "sha256-z6vW43W2VjxW4JfPenUuByF4BaCEh9zc5RhH/5BTfjw=";
    }
    |> getFiles [ "RotP/RESOURCE" ]
    |> compressScummvmGame "mads";

  daggerOfAmonRa =
    fetchGOG {
      game = "the_dagger_of_amon_ra";
      fileId = "en1installer0";
      sha256 = "sha256-7oQX9WKFIjjc1pmI5ag+FJHCBkzsDj15cN2iWbCB2Oc=";
    }
    |> compressScummvmGame {
      engineid = "sci";
      sciSupported = true;
    };

  torinsPassage =
    fetchGOG {
      game = "torins_passage";
      fileId = "en1installer0";
      sha256 = "sha256-snp6YKb8+zjhgyEJk8j9Oo+VwAxuIPrqvHPNzAt6+Ss=";
    }
    |> compressScummvmGame {
      engineid = "sci";
      sciSupported = true;
    };

  beneathASteelSky =
    fetchGOG {
      game = "beneath_a_steel_sky";
      fileId = "en1installer0";
      sha256 = "sha256-CEjidQErxanbXpIiq6SxzCnKwlZEdL5+cCaha84ZfaU=";
    }
    |> compressScummvmGame "sky";

  # queen.tbl not in GOG data, compress_queen needs it (scummvm-optimize.nix)
  # -- grab from pkgs.scummvm.src, no new fetch needed.
  flightOfTheAmazonQueen =
    let
      queenData = fetchGOG {
        game = "flight_of_the_amazon_queen";
        fileId = "en1installer0";
        sha256 = "sha256-Egml84/1hn9zHXFNPJOb5bpZ3qTJCJLS+1PBYF8P6rQ=";
      };
    in
    pkgs.runCommand "flight-of-the-amazon-queen-with-tbl"
      {
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        cp -Rs ${queenData}/. $out/
        cp -R ${pkgs.scummvm.src}/dists/engine-data/queen.tbl $out/queen.tbl
      ''
    |> compressScummvmGame "queen";

  lureOfTheTemptress =
    fetchGOG {
      game = "lure_of_the_temptress";
      fileId = "en1installer0";
      sha256 = "sha256-OWbjC0aXIP43ri37W5t8+5DEg56Y9F/+lhpia61LZE4=";
    }
    |> compressScummvmGame "lure";

  savageEmpire =
    fetchGOG {
      game = "worlds_of_ultima_the_savage_empire";
      fileId = "en1installer0";
      sha256 = "sha256-4ICpc69t8OCA1jEgEtfzguJNyXj8o5BsVXbOAS4OmJ0=";
    }
    |> getFiles [ "SAVAGE" ]
    |> compressScummvmGame "ultima";

in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games = {
    teenagent = {
      engineid = "teenagent";
      guioptions = "sndNoSpeech sndNoMIDI";
      extra = "Alt version";
      description = "Teen Agent";
      path = "${teenagent}";
      gogId = "teenagent";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/8e054c9fb4824539ea93499ea3fafb06.ico";
        sha256 = "sha256-FBSvWyok2YD3pQXXrQRyZ5EuxUiCwPR2ifGNVybp9VY=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/acd9bdac8824615154e7f1868f29acf6.jpg";
        sha256 = "sha256-tv39Oelv5PyKnEqNptuCg2L7ielnDTN27K4ANgpDDbg=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/6207e48bc2612a0b21c093b4a46a3be8.png";
        sha256 = "sha256-0vkuA2+72IbbOhmjNytLqaJxCM3OHe+x3lpagOu2ZNo=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/a143d10a8c4f749e7ea0f3f40674e636.png";
        sha256 = "sha256-XdcxoW4+zJRH/oRjfrjQ6LE+Iwlqz1LFWNm343ratw8=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/c4d856156b2c629314b9edd13523fe8e.png";
        sha256 = "sha256-HLeMzGPFfuwodbtrTyuIj3OuP07YeZNZuFkzhXgtLC0=";
      };
    };

    ultima4Enh = {
      gameid = "ultima4_enh";
      engineid = "ultima";
      guioptions = "sndNoSpeech";
      description = "Ultima IV - Quest of the Avatar - Enhanced";
      path = "${ultima4}";
      gogId = "ultima_iv_quest_of_the_avatar";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/75639ebffd530f09cf29eb0efb05a3d0.ico";
        sha256 = "sha256-EwR7N3zJsNniQBsscyGLZhs+5+OiUswvmTJGBmvLcLw=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/f42fe38d01177377792cd467db65d352.png";
        sha256 = "sha256-kUp6ZiHxES76wILMS2H8H0ir6q2DD5QJgYVvG6emwYo=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/5004917907a5a28fd729ad6f252bd3db.png";
        sha256 = "sha256-QprZJa5j2R/A05q6okHRduCXsoR8W57x4Pi7DkHFTT4=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/8a601280b3f1c69f8a06a7fe60a6d4de.png";
        sha256 = "sha256-sniKxy+D0V+iL6emOH8ZD6xjtwxkGod4PnWkfjbFSz4=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/5d5b3b7e818e3c48436c66f1a2191aa4.png";
        sha256 = "sha256-pDbqgqKqfx4i6dpDTrARyd+oonza6yfzxxC0Y3F96As=";
      };
    };

    dragonsphere = {
      engineid = "mads";
      description = "Dragonsphere";
      path = "${dragonsphere}/DRAGON";
      gogId = "dragonsphere";
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/4dcae3c831b59651f5f4d1bb7ee82f3d.png";
        sha256 = "sha256-w6eA6l62MJLMcpaCDgawwwlWTkxdaxXww8gJbaAvCYU=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/681140d22d80d6c3c95cafd19b89c188.png";
        sha256 = "sha256-ig9vDd6PDhQGV4tDv4ZAAM8W1RM1h2ltKTntmCyvBsA=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/f0888b419473030152c94ee12c7895ad.jpg";
        sha256 = "sha256-iZOhwj+fItABJUGNXbH7SAJt5VcZElgf/jPg7t2kozQ=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/8c9a14ffebb7677d033ffce847991293.png";
        sha256 = "sha256-ngELHSjnvVqvvOvluFh1G+4GiIyF3U5FlMlW7MbQ96Q=";
      };
    };

    martianDreams = {
      gameid = "martiandreams";
      engineid = "ultima";
      description = "Ultima: Worlds of Adventure 2 - Martian Dreams";
      path = "${martianDreams}/MARTIAN";
      gogId = "ultima_worlds_of_adventure_2_martian_dreams";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/09ffac1a62f6d5b620ff2499465b65c6.ico";
        sha256 = "sha256-H7e1eHEgz+ALSh/iRtljijuZ1Lt2vqbapHqPLjXif1Q=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/4d4c0c9cffa15b02c38b92759e7e1d1b.jpg";
        sha256 = "sha256-vuqKC0IAktAhFbBUyzQTldxcalNM3MX5vdBypRdmVQY=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/9ae548c513b3186a6ffa01e5567f8e25.png";
        sha256 = "sha256-+P8Mv5w7b7es7uOod2LLbHW4IJZZAXD4zIitlt8CB64=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/b762a19d81c2b8d11d04ca87453af7b5.png";
        sha256 = "sha256-joiytZOm3mW80PAHjGZnrQvBylO8+wPtqWBnwOiZMXU=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/963023db12c1b269a5e1b2fcd4046352.png";
        sha256 = "sha256-qr07/u9GTcCnPgtlHP0zvBSJyR3NfpFiTIxwX/Lozi4=";
      };
    };

    bladeRunner = {
      engineid = "bladerunner";
      description = "Blade Runner";
      path = "${bladeRunner}";
      # GOG relaunched this as "Blade Runner - Enhanced Edition"; the
      # library API now reports this gamename, even though the original
      # "blade_runner" slug still resolves for lgogdownloader fetches.
      gogId = "blade_runner_enhanced_edition_base";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/2df9225a03b1cfd5294697afe5cbcd91.ico";
        sha256 = "sha256-yk2qzz6uU7duEGL2Fv39NvTcrlhxO7AkZLrtkyYVhe0=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/e698959e9b93e4de823526327ffed84a.jpg";
        sha256 = "sha256-5UXPxi8h5Z/TNhT4WG55XIwtl0HMrFAujYoKyI23fRI=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/7f05e19bb9d0cb347a6b4a839b2385c9.png";
        sha256 = "sha256-H3V/UNcaVhtjZLhog8xyjmCKXORzfDzgXRm/ICejbks=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/c1cb6c25ef752d4f357bfe42b2d48cf3.png";
        sha256 = "sha256-CrrzJr2SoUG+fGst6V5tSocQOka5y9IqtNlb8hpziuQ=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/514d7c19ec76427e74c6688774f4e2e7.png";
        sha256 = "sha256-r5ASXMKiGiGb0lMGJBg/a6BpY23K/nuytNPLbTe+04E=";
      };
    };

    grimFandango = {
      engineid = "grim";
      description = "Grim Fandango";
      path = "${grimFandango}/app";
      gogId = "grim_fandango_remastered";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/b542ca4b39e12006c810855b4a053e1c.ico";
        sha256 = "sha256-685fbuzNPP9QabNyvT2qprdjKDRxEjcRDK9vTHQDRLA=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/43cf3ae60279360eab2d678461a565c3.png";
        sha256 = "sha256-Vx9/UfXahDHTTuJ1JIVD3CUlc3BIQAwPIbHMSeYtS+M=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/11b99b502b6eeca494fabcc6ee7ca553.png";
        sha256 = "sha256-2+mFmCodAiwc0R2nYz9nyVmUB872EKdEYN21RSUruYg=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/28e02db6178b522319b46e74621a47b3.png";
        sha256 = "sha256-Q9dxkxB7qxubzjqvmj12hlFD/lNT6tXgzltpDTa7+kA=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/f9fa2e8f5ed2891ee7bd8a7f8b06c0ef.png";
        sha256 = "sha256-AOEfs1/ioR4hrYxavPjzK60P/v8qmp+VVAZ4Zca+HJw=";
      };
    };

    conquestsOfCamelot = {
      gameid = "camelot";
      engineid = "sci";
      description = "Conquests of Camelot";
      path = "${conquestsOfCamelot}";
      gogId = "conquests_of_camelot";
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/db4a1766c395480fd973a96c6105f86e.jpg";
        sha256 = "sha256-j5v4XPO1CmpeCbDrC8hfrzwj2fpLiXNR50ou/EyCfXs=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/f340ba2cec2ea3f443587dea07e3ccd6.png";
        sha256 = "sha256-fAU2GiqNniL6Qfrh1xl69NoUeCyYUz/T8/3XmfrkyKw=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/1cde98df96e0348adff0b4cc8d0d86e8.jpg";
        sha256 = "sha256-vILEXURLwZyKyJs+UbCIwu71JPXQ97rZwQVv7IFPz1c=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/107037604f12bc8ae27e444773372fef.png";
        sha256 = "sha256-vcw4TRrgEUEl7kawrMytK6ZCRE2IncdrrunZPKeq2OY=";
      };
    };

    conquestsOfTheLongbow = {
      gameid = "longbow";
      engineid = "sci";
      description = "Conquests of the Longbow";
      path = "${conquestsOfTheLongbow}";
      gogId = "conquests_of_the_longbow";
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/2ae113b9be03cd766e76cf4ef5aecf61.png";
        sha256 = "sha256-czz5oPYA1g4aNFQkSx9wcVfUwktpUgz9Orphcq6ZPGA=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/f2428cf0bd03797c29e68ff45e44f290.png";
        sha256 = "sha256-TMm7FvsZNdvT3XaN5Xx47Tw5kuZ2cZqVFpk+ytnnXJ4=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/d424d138fe039d48b93d955094390b12.jpg";
        sha256 = "sha256-i5Sj3AenkHPs/Z6GenS1M0yiQJmebU9FIpPG/+FK4Rc=";
      };
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/230a11d4f53fa5ecb16c69d668eb8456.png";
        sha256 = "sha256-ARYCkD/2zXh7n/WQmwO15eswQvv5sx0hE5MMHMtEVLo=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/22c6baccafed030ed00761fc8c4a2db9.png";
        sha256 = "sha256-iT2UXAMn6p7bB0sDM3PelDjgPJSxVvqz9Z6r3tP66ww=";
      };
    };

    returnOfThePhantom = {
      gameid = "phantom";
      engineid = "mads";
      description = "Return of the Phantom";
      path = "${returnOfThePhantom}/RotP/RESOURCE";
      gogId = "return_of_the_phantom";
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/cd1b4617f3682d2490d6f905ff27929e.jpg";
        sha256 = "sha256-ipnqa+d5PuZ39OU1goWRLAollN/q9fEx+U+laD7tlcE=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/e68562dc856a4da1af614dca107a334d.png";
        sha256 = "sha256-2BL/RSBvN+UT/nV7MyK1ZJkoZEUMp7BomJqtX1dtMSM=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/10d57d0d918b08e5c27c7591f9d1757c.png";
        sha256 = "sha256-CC9Z9oJGV1vJv9OlDT61iO4eFzbIO6g0cGrqiSgqS4Q=";
      };
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/8cb8581de27112633c60b4a3c84d430b.png";
        sha256 = "sha256-G48wS+hY36bAnHEFMNau/rrmVkufqepsVX63ZaoPFcU=";
      };
    };

    daggerOfAmonRa = {
      gameid = "laurabow2";
      engineid = "sci";
      description = "The Dagger of Amon Ra";
      path = "${daggerOfAmonRa}";
      gogId = "the_dagger_of_amon_ra";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/2ddd93f42feeba056d189ad5a84f1793.png";
        sha256 = "sha256-/rU6IqaygdbfI8qOAltpls8R8xO/4qC1Nze8zEmS2Uk=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/74db80486179f9e43bed14f2d28c70a8.png";
        sha256 = "sha256-tFHp9D0v2UB6fAKs9vDBrqQdSIIl7YOpaBbiFjTO0gk=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/a484ceeba120c786040f045c544632eb.png";
        sha256 = "sha256-kYw1Y+G8sNNYzbop+Rkj6ZEbl1WwwC/YjkC7aNNTut8=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/85a099aa13f316b3ff805b7985442811.jpg";
        sha256 = "sha256-Lqc2JbYuJmclRY5ANQt87wxNt6IhrFxN8w5oGb11Rwc=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/c83aaa1a51ec03534bee2ef92c027973.png";
        sha256 = "sha256-TtPStO6LYJi17Hj2kUk1gGbqcJGBEVcm5O0Q9XvxVao=";
      };
    };

    torinsPassage = {
      gameid = "torin";
      engineid = "sci";
      description = "Torin's Passage";
      path = "${torinsPassage}";
      gogId = "torins_passage";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/e80ba3de4e2f156e3bdf5b3596b36ca4.ico";
        sha256 = "sha256-do+VIdvyXiT+2yNutn9OTmAWsj3/zFoBmwvUNvR0by4=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/16a8b936c7b8973bf50086d044cc248a.png";
        sha256 = "sha256-+Zc81eS7vDuQPsYedERWsLrdhglRMtz9HknAN/PQTzU=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/450fe1e49f01e991c3e005f55bdda5a5.png";
        sha256 = "sha256-4+OabkZNC5u391bz5WPPdpB+QrkvNZHYHCn5dtN9+J4=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/e3ddd82a9a525f3b32d4ba04ae827d24.png";
        sha256 = "sha256-l8QLIov9hayv2plcCjwLuGT/pc/HtyBxJtr63hgWQ/0=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/4d5cdda8ef91df5f5bb3833a5e315e49.png";
        sha256 = "sha256-/aUk8qHN0iIkq/T1pnYfp3VeX1Vy/QfPjgL7eRb8CU8=";
      };
    };

    beneathASteelSky = {
      engineid = "sky";
      extra = "v0.0372 cd";
      description = "Beneath a Steel Sky";
      alt_intro = false;
      path = "${beneathASteelSky}";
      gogId = "beneath_a_steel_sky";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/ab739b9148fc66c94472053de864b77e.ico";
        sha256 = "sha256-+uJ8+Js9D6uE7NCUO30kBJnWKRiphHEnJL3KZhXBFPA=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/f69e1c25bd59a881c4eece81cf361768.png";
        sha256 = "sha256-SbN421Hx4/8Q4LKvxRqDOtAuH4hZXwVCt98nzbp1SDg=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/714bb9ae1e0f98eab9dff4c8edaeb6f8.png";
        sha256 = "sha256-eh8RZZ4jWigusJFCDcHrSoAnQo71RJGMXiUpSMl9lgc=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/dc213c8715d575b5e9c1d87fb77dc865.jpg";
        sha256 = "sha256-jfWaetgPnOLzLlcqSue0Ga1ePuY9Clpc6oFKe/cyG1A=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/325e88548146477d481bb4a0436d192d.png";
        sha256 = "sha256-KeU++pcfBfg2vqB0CGwF5H23WWZJHsSG0qnfa5EiL3E=";
      };
    };

    flightOfTheAmazonQueen = {
      engineid = "queen";
      extra = "Talkie";
      guioptions = "gameOption1";
      description = "Flight of the Amazon Queen";
      alt_intro = false;
      path = "${flightOfTheAmazonQueen}";
      gogId = "flight_of_the_amazon_queen";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/1a3b8604b81e1e51337a3663bf99dd9b.ico";
        sha256 = "sha256-JqnKLOhDnSKtDkDiPF5O+Re76YjTbtiaAoYaultqDlg=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/34306d99c63613fad5b2a140398c0420.jpg";
        sha256 = "sha256-nqIiKajKIzl4rd1/U154RySgabf1UErEc+j4CnhhQt4=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/fba058470460d044d887af9c598f1cb3.png";
        sha256 = "sha256-8rWlME2DXRqQcK3oXgMijv+m33nCKOLdOIWiYGyzTt8=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/d2108e348e0b980c6ff8508fbb5c9c31.jpg";
        sha256 = "sha256-U3V+Q0sFDNKZWZDeAecA4uC8smyVoYQqUHNwH75B1QA=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/979347d17d4e524005bc1a8e8101fa3a.png";
        sha256 = "sha256-725+wp7W+3OPAPYJfF+/7S/0Yp2/APpdKLbTP4re0ZY=";
      };
    };

    lureOfTheTemptress = {
      gameid = "lure_1";
      engineid = "lure";
      extra = "VGA";
      guioptions = "sndNoSpeech gameOption1";
      tts_narrator = false;
      description = "Lure of the Temptress";
      path = "${lureOfTheTemptress}";
      gogId = "lure_of_the_temptress";
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/78dc319ed858c2aaaddd5cf24505d4e1.png";
        sha256 = "sha256-F7R5k63QM0qjRpNPC5mv4wD6zqaJDX5oeAvhMTj81yE=";
      };
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/2132c4c315e47bc5548077bd11f88e03.ico";
        sha256 = "sha256-ahDh1M2gpwwrLqofhmjePNEkZdfyldiL/RUsBLf2wmQ=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/c80bfa00454a7564c07c0559808294fa.jpg";
        sha256 = "sha256-OR7kk02mKXN4W+UMuL4G8IDXN97lnHaAe9dOpI+24CE=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/20d8bd8d98bf59b67659fc3d5460b513.png";
        sha256 = "sha256-i3PMhTP+UY9P6nE970nBF+arBIt+xrYOQvaHsrWdfCY=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/f9cb118d9b39953affb7ec8db4f41c34.png";
        sha256 = "sha256-083Y1jPneFrfOu3qGAZWvpwhp/lprV5SXmDHT00MkvU=";
      };
    };

    savageEmpire = {
      gameid = "thesavageempire";
      engineid = "ultima";
      description = "Worlds of Ultima: The Savage Empire";
      path = "${savageEmpire}/SAVAGE";
      gogId = "worlds_of_ultima_the_savage_empire";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/8c3fd8b7d87a3036af991a24120f0775.ico";
        sha256 = "sha256-CKXsgrOtYTNYuJEXOhvyVAhAxuVNytDWWt9A0gbsqAk=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/a1a527267c0d33a86382a03c4c721cd2.jpg";
        sha256 = "sha256-er42pCEWt5oSzuXzuXTdYUWSSkJ2vIo04oWXLZ/aZFk=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/5c81d88dcb1d503d8f79ab83bcd20ddf.png";
        sha256 = "sha256-OUR2zRGa6Wvsy0guqGiHnFOOGiVgQzG7jXZRNSyzZVY=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/00567a496ef30dee335587520f478255.png";
        sha256 = "sha256-cDOW1qucvUCYxNwnA7YqLOfSJcADy2rsT7IVb3z77y8=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/3be1e43c45c1332103695ea502ff9207.png";
        sha256 = "sha256-cMuKcclXIZcw4ls0/sILstXggcAN9/z6vQffjRLACi4=";
      };
    };

  };
}
