{
  config,
  lib,
  pkgs,
  fetchSteam,
  splitFiles,
  mkRom,
  ...
}:

let
  sadxSource = fetchSteam {
    filelist = [
      "system/SONIC.PRS"
      "system/SONIC2.PRS"
      "system/SONIC-CH.PRS"
      "system/S-TAIL2.PRS"
      "system/G-SONIC.PRS"
      "system/SPINBALL.PRS"
      "system/LABYLIN.PRS"
      "system/SONICDRI.PRS"
      "system/S-DRIFT2.PRS"
      "system/TAILSADV.PRS"
      "system/SKYPAT.PRS"
      "system/MBMACHIN.PRS"
      "system/SONICTAI.PRS"
      "system/SONIC_TT.PRS"
    ];
    appId = 71250;
    depotId = 71251;
    manifestId = 3248206210397098900;
    sha256 = "sha256-RXVN2hQbU5Zn4SKSnJ72Qy2sOf9NbV6NAmL4vs0ZDfY=";
  };

  sadxDecompressed =
    pkgs.runCommand "sadx-gamegear-decompressed"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        nativeBuildInputs = [ pkgs.puyo-tools ];
      }
      ''
        mkdir -p work out
        cp "${sadxSource}"/system/*.PRS work/
        cd work
        PuyoToolsCli compression decompress --input "*.PRS" --overwrite
        for f in *.PRS; do
          name=$(basename "$f" .PRS)
          mv "$f" "../out/$name.gg"
        done
        mv ../out $out
      '';

  prsName = name: "${name}.gg";

  sadxRoms = lib.listToAttrs (
    lib.zipListsWith lib.nameValuePair
      [
        "sonic1"
        "sonic2"
        "sonicChaos"
        "sonicTripleTrouble"
        "sonicBlast"
        "sonicSpinball"
        "sonicLabyrinth"
        "sonicDrift"
        "sonicDrift2"
        "tailsAdventure"
        "tailsSkypatrol"
        "drRobotnikMeanBeanMachine"
        "sonicAndTails"
        "sonicAndTails2"
      ]
      (
        splitFiles (map prsName [
          "SONIC"
          "SONIC2"
          "SONIC-CH"
          "S-TAIL2"
          "G-SONIC"
          "SPINBALL"
          "LABYLIN"
          "SONICDRI"
          "S-DRIFT2"
          "TAILSADV"
          "SKYPAT"
          "MBMACHIN"
          "SONICTAI"
          "SONIC_TT"
        ]) sadxDecompressed
      )
  );
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (sadxRoms)
      sonic1
      sonic2
      sonicChaos
      sonicTripleTrouble
      sonicBlast
      sonicSpinball
      sonicLabyrinth
      sonicDrift
      sonicDrift2
      tailsAdventure
      tailsSkypatrol
      drRobotnikMeanBeanMachine
      sonicAndTails
      sonicAndTails2
      ;
  };

  programs.steam.games = with config.games.emulation.roms; {
    SONIC_1 = mkRom {
      name = "Sonic the Hedgehog";
      rom = sonic1;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/10fb6cfa4c990d2bad5ddef4f70e8ba2.png";
          sha256 = "sha256-QozAShl/YQVjw1B1h8KFiA5/mUC+WsM/7XmvdxXwxNU=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/6babf6559ebc185d02860ca79b1088a5.png";
          sha256 = "sha256-R9HU9yDg1BqJr7ipUs06K0bg+Iip7Bu59T8Ue1ov4XY=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/7b9d31aa17b849b238ab79cef0733041.png";
          sha256 = "sha256-uU8YwHGbKg0fZxZFCwT8yANtHnt90EeS25lACWK9aJ8=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/9fe06b33ea459f011178ef3156ff09c7.png";
          sha256 = "sha256-hMF4F9ogdMgdb9vIlq8nyDnigmVRY6HT+k5vs4EHYCs=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/47c95199b010148056eda6ac6f961c63.png";
          sha256 = "sha256-CUA0x4/5qBhT4PS/uRpcGQ8p3CW1YhLZNeg2RoXnOWE=";
        };
      };
    };
    SONIC_2 = mkRom {
      name = "Sonic the Hedgehog 2";
      rom = sonic2;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/255ea887b8bca36797426dfb35a809cc.png";
          sha256 = "sha256-BPpg8PwM8o5F9bRXd6SIC16wMi//vZ5OIGax6A52Xts=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/70e48fb761d61fad9ddcbc4a1b889e68.png";
          sha256 = "sha256-4iTwdJLwMA6tSGM1oZ8dQPPDoTa2O0yoeFfnvQbLhmo=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/fdbdddfe8c4df643ec18e5f931bada26.png";
          sha256 = "sha256-uTL4KoqHQ5ROTxk1S19bEy8iSEr4Nyz/5PB/PvGrbU8=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/53e8fdd6e41b291701b286a9db8f23a7.png";
          sha256 = "sha256-tUt2GoDZBvpJpOJm9pb0GiLerEedWZivJuXHFRTiRUw=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/ab96c631d50e81c5f961bcbf25e49475.png";
          sha256 = "sha256-YD2SxkSOIa06iDUEGanp2OZJzkvChHfQxp/WDlvWmVU=";
        };
      };
    };
    SONIC_CHAOS = mkRom {
      name = "Sonic Chaos";
      rom = sonicChaos;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/fca758e52635df5a640f7063ddb9cdcb.ico";
          sha256 = "sha256-kdzMsX4sX7y4vnL721Gt1wmbjtR03usYD2d4kbH3jfs=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/a2682769e1361755c84ef9f75bf0d1dc.png";
          sha256 = "sha256-lyBxob8GllYbGSawwT4Et+UVSLq27+QAE2FEMBoTPWs=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/43a30d90c4430a7de2ec7fc705164403.png";
          sha256 = "sha256-sP9ytCxiOid8Swc0g9xMF/+JEsR8eqj38fJUyojnbCc=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/271afefd532164546cab9f167a3a390f.png";
          sha256 = "sha256-kFcOMlDhr1XZGJgoQsdPCegWDHujCdOucIVqZWc1gcs=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/f623335c7b158cd2451c10e2deca8a84.png";
          sha256 = "sha256-YNpyLZVE9rYiVRd1E6Aow4VgCHbcIMtp/ne6KqvM9Oo=";
        };
      };
    };
    SONIC_TRIPLE_TROUBLE = mkRom {
      name = "Sonic Triple Trouble";
      rom = sonicTripleTrouble;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/6b5617315c9ac918215fc7514bef514b.png";
          sha256 = "sha256-nlu72B5QcNtkZcipF2QglNJyriks2BqvFR17gix/uTI=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/7c237fddfd9f6c39ab306c4cc7289746.png";
          sha256 = "sha256-Pusqd0tQDNkFwMJwFdfSMRYhWfvI641jhwe8eM6pLe4=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/f3b824b12593b0f51672e306ae05e7fa.png";
          sha256 = "sha256-6JCITTzQlwQDi9DOQUrxzCtgNik98T69i3Gj3ehyDC4=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/5e5242e9f2a97fb1371c42efc8804e88.png";
          sha256 = "sha256-JHxh5mkpB0s54Sh4QuBFKNngu4PWVdn3BkaaHz1eMks=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/2075c1dd62a44cb74df76e63f4d7e331.png";
          sha256 = "sha256-B/IHu+uDiFjeha0DXwJssHXiqnq0bJ8Zm2Pq/aSrm/M=";
        };
      };
    };
    SONIC_BLAST = mkRom {
      name = "Sonic Blast";
      rom = sonicBlast;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/b192238c5f2084617424714334351ffa.ico";
          sha256 = "sha256-mnWwHFOS7CUdhoDFAPRZxhkXdGE6Jxh+Ew9P2JqFsZk=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/8d9801a176cdb6f39a22279f5f0ebf63.png";
          sha256 = "sha256-F8AgD5hlClCx92G4mMf8IYPuval9IiLdU6217uCfpwg=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/51b030d05fdce1d571c4f55eed93d323.png";
          sha256 = "sha256-bSiJGy57PSm4wEkXI2ALAqZnDjoDn7csKjT3Nb5Dv/A=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/7f9ae5a7d3466ce103fd36a14d2a27f9.png";
          sha256 = "sha256-2rIFUffztSMlIhhN6DzBe+dUFFrMC9ice1mBKzHt7tE=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/26efa2c1ae0ada479b8e539cffb12446.png";
          sha256 = "sha256-rpqgEubd2bRACdcFBoHOBo4S4+XmTaoNrupTiWXfHk4=";
        };
      };
    };
    SONIC_SPINBALL = mkRom {
      name = "Sonic Spinball";
      rom = sonicSpinball;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/5527eaab87a00dbe1614481ef174f285.png";
          sha256 = "sha256-59f2td0LQpprx3hwLOY5DLpbM/SMe18gKF6rWMnsNao=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/ec6f75eb35cb02bb969f3441998c51d7.png";
          sha256 = "sha256-+cxeElychX5z73zHNDrR9NKXckgqvGZJQOFs1Np8kaQ=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/b6bd9a3f86f59c7c58916b4aa946a239.png";
          sha256 = "sha256-DD3ad42BLxvRVHk7NrNE6etzUipwXpRaxHD4aMtgAnM=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/4855678ca8b08b092ab353309336db8a.png";
          sha256 = "sha256-QoL8VKCNd4JeDQKzbyNjkB6bEKMYd26eyuE3VpGI5/c=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/95b2a1df756b9e6e67bfacd25c2c6110.png";
          sha256 = "sha256-Dpmg8QUZoqkBZSryNWaL6GUPmDjp86u4mlTBZMEbyxI=";
        };
      };
    };
    SONIC_LABYRINTH = mkRom {
      name = "Sonic Labyrinth";
      rom = sonicLabyrinth;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/d89197e84e49d007cfe7f52051b0a3ef.ico";
          sha256 = "sha256-zChO2jecsLQH5swSBUyQabmWQqmRBKPKT9nRm5ESS1s=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/7db42fb8cdd3c47839eadb1414c475bf.png";
          sha256 = "sha256-dIfoVOkh6HgJPxI0RWn442o5zMDXbPPkWX7LWP/hRmA=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/fba951fde2b9ba4ab490dfde8c487f55.png";
          sha256 = "sha256-Z4PVZW4+jlzEf9F05DsqYVNpFypSYWhQI5ctY923A7I=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/1cac981fb61dc0e4a41e6a8508552803.png";
          sha256 = "sha256-GC5aQEJEC6ZmQn/BoL4kzK0KL0leCWlOTSQqXcwHPLE=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/b8613ee153c2d86943bde55b81d7492b.png";
          sha256 = "sha256-nVEH9qysHoIsHkKJwNpHCT3GXusECpEdepUvoDPPkxc=";
        };
      };
    };
    SONIC_DRIFT = mkRom {
      name = "Sonic Drift";
      rom = sonicDrift;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/4c600d3d9e5cd9e6899732fab33cbccd.ico";
          sha256 = "sha256-AfIzSDe9PgPV5K0X/7Fgvtxae1886C8rfpeJ8yXVL78=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/2ddcb0ccdab00d0a197d574a0109ede1.png";
          sha256 = "sha256-WtAJfAInAN63OPbDwDiFsg0P+MW1rU916iB0ff0oK6I=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/f0d1e9fd1b88034a6ad6098d9c1e34db.png";
          sha256 = "sha256-zUmpaz9oSTzTZEstmrZcluRLKIJfs6h3GcSH5WcjLhI=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/e3f70ca8f71778b1c4361e014011de7b.png";
          sha256 = "sha256-a+JIFC5mkXHZOkdzbiX0GIXzkT0lY+bW1rhMUNoOTig=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/4d7efe87e47389ee9f84559335b86a63.png";
          sha256 = "sha256-6Bnjkz8cn/r+3t4/PLR5rrRwWuAA2fRP+iuZD2JuMNc=";
        };
      };
    };
    SONIC_DRIFT_2 = mkRom {
      name = "Sonic Drift 2";
      rom = sonicDrift2;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/cfa57ce2b96aa179a800c08015a481b7.png";
          sha256 = "sha256-o0AUQ4oxfLM2J3m7iUpWzxGlUCg16PYKqDiuT88+Xqo=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/39ad896d999e6ae461ae14a8bb567924.png";
          sha256 = "sha256-iXVNnnxPDQGTcghP31FskEypdJILZLdrKRL7cD43rLc=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/3b19a3c579f379423b53cb218ba03baf.png";
          sha256 = "sha256-aH/78mxkdrP+/w/8DtfVXSFTh260aOccB/u6jagPe+8=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/33d3cb12116a371ee563927ade87d461.png";
          sha256 = "sha256-BI7uUkqeOpY+ngIVL1fFbSf6Lx1Bn3HC8SATIFrMEVQ=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/c2d8230bf04b89e2d4cc27d9c27576f7.png";
          sha256 = "sha256-UjiKBD8cG0UzaZrqCbdri+y8asOYONxcMJdJmnas6V0=";
        };
      };
    };
    TAILS_ADVENTURE = mkRom {
      name = "Tails Adventure";
      rom = tailsAdventure;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/58f2e2c0a23fffecc13834f1fd7c4eb0.ico";
          sha256 = "sha256-RihXq3h3WDBGQNGrLIwgeJB6yZfYjYhESHn1q9LEJAw=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/447d8ce3ef1166710a63af6312ed56cb.png";
          sha256 = "sha256-ZLXJAjnvQyh+YXFRsUIXq5or+RWPEXycE5jiJH/Xnqc=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/b6b505ff2025d4dec937e9dfba52e4c2.jpg";
          sha256 = "sha256-MNgER7R7nqUcOqFH5cE0lJiXa6UlgZp5W4sbOcPRy8o=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/eebf3eafb4a2bc369a213e75c0d78553.png";
          sha256 = "sha256-rC2oLtbY5rrDsAcvkLe36TGiOIbcc4DGX1Hiawv4pLQ=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/fd1cf65576f0c5fb963ae706c089d63e.png";
          sha256 = "sha256-EtEaPlixbkuu3feKM3T2JK/rZowoySSTqhZf8do3bRE=";
        };
      };
    };
    TAILS_SKYPATROL = mkRom {
      name = "Tails' Skypatrol";
      rom = tailsSkypatrol;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/61f7dbb5551741c6974a6fe7fc32b454.ico";
          sha256 = "sha256-Rkqx0WZuPtmqhf8Q5FlSWMozFR3SHRecqUaa9nQuDW8=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/631955c58c055ef63799afb638e10c88.png";
          sha256 = "sha256-8/AmN4SESccmoxDA2V5GWFdW1CnYtChpn/gEXeMfLGc=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/6e5bfc684c727ff09b14b57d2335929f.png";
          sha256 = "sha256-kbMby5GyWMoHWq6gOs2UvPTJA9+JpQhPy3cCi4basIo=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/76108f6ac5e9dccfc581a09f7e5ef333.png";
          sha256 = "sha256-oOKjkFSn4ZxK/Q5eJEyo7hbLN3s8G+FHuUXTyiPt45M=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/9a7524e7a36bca7712594545d17d2160.png";
          sha256 = "sha256-XHIyvq1OWOEGBmVjiQOe57VjbsQKC2uIWmAF9g5qV1Q=";
        };
      };
    };
    DR_ROBOTNIK_MEAN_BEAN_MACHINE = mkRom {
      name = "Dr. Robotnik's Mean Bean Machine";
      rom = drRobotnikMeanBeanMachine;
      system = "gamegear";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/09edf2c698a3b122d8118387ce2642ff.ico";
          sha256 = "sha256-z6FgXHOMSMPgFBh19TBhe7LYDNdojq23BXGSKAW2vYs=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/a662ca88a074f175f029638d8e37a1a6.png";
          sha256 = "sha256-6So7D3WbSUnh5458/XlmvU6GIXDEddgpXnLAPq66xts=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/1211f0aa22b0518fcf1694d875ff259e.png";
          sha256 = "sha256-rgSQ5KQBbnNjuAU53ytnKgKn9Ls+w2imY2NU9AgMNos=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/e5bf23321ac8680df3177219150291c8.png";
          sha256 = "sha256-k5sgaU7lSfJzEiYRLMMp9AFCEo7Wkicf7o8AH4s/4NE=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/b9eddbc16c03e3c49daddabbead85e66.png";
          sha256 = "sha256-rmpanKpEuDplXVffC0zC+dNwbQ5Q4RKKJZ0kh66w25g=";
        };
      };
    };

    SADX_SOURCE = {
      disabled = true;
      name = "Sonic Adventure DX";
      steamAppId = 71250;
    };
  };
}
