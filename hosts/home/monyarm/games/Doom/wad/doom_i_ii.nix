{
  config,
  lib,
  pkgs,
  getFile,
  fetchSteam,
  mkDoom,
  wadFilter,
  ...
}:
let
  DOOM_I_II = fetchSteam {
    filelist = wadFilter;
    appId = 2280;
    depotId = 2281;
    manifestId = 557527948370603647;
    sha256 = "sha256-KIX9HRzQyQ6YawMVYGVk43z88bi55JUy3HNKNTMA2y4=";
  };

  # Corrected PC versions of the hidden Original-Xbox Doom/Doom II levels
  # (https://classicdoom.com/xboxspec.htm).
  xboxspec = pkgs.fetchzip {
    url = "https://classicdoom.com/xboxspec.zip";
    hash = "sha256-an/n2O1yEe/i0j3V/XbP9mXGFRYjXDenNjl1h3eI4gI=";
    stripRoot = false;
  };
in
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    # Classic base/ versions -- uncensored (no red-cross replacement etc).
    # The rerelease/ files are KEX-era replacements with altered graphics;
    # base/ has the original retail content wadsmoosh/WadFusion expect.
    doom = DOOM_I_II |> getFile "base/DOOM.WAD";
    doom2 = DOOM_I_II |> getFile "base/doom2/DOOM2.WAD";
    tnt = DOOM_I_II |> getFile "base/tnt/TNT.WAD";
    plutonia = DOOM_I_II |> getFile "base/plutonia/PLUTONIA.WAD";

    # KEX rerelease/ content -- bonus material not in classic base/.
    nerve = DOOM_I_II |> getFile "rerelease/nerve.wad";
    masterLevels = DOOM_I_II |> getFile "rerelease/masterlevels.wad";
    sigil = DOOM_I_II |> getFile "rerelease/sigil.wad";
    sigil2 = DOOM_I_II |> getFile "rerelease/sigil2.wad";
    id1 = DOOM_I_II |> getFile "rerelease/id1.wad";
    id1Res = DOOM_I_II |> getFile "rerelease/id1-res.wad";
    id24res = DOOM_I_II |> getFile "rerelease/id24res.wad";
    iddm1 = DOOM_I_II |> getFile "rerelease/iddm1.wad";
    extras = DOOM_I_II |> getFile "rerelease/extras.wad";

    sewers = xboxspec |> getFile "SEWERS.WAD";
    betray = xboxspec |> getFile "BETRAY.WAD";
  };

  programs.steam.games = with config.games.doom.wads; {
    DOOM = mkDoom {
      name = "The Ultimate Doom";
      iwad = doom;
      wad = [ sewers ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/d55deb675302633e82bad6072e853c00.ico";
          sha256 = "sha256-/J7JPip+p8jOCeUT5UxzEspH49k1Le97otdwdi1HHrs=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/d232a954dc1b93636db520e4e681a73e.png";
          sha256 = "sha256-QNGIUcUUtpwbia5fMHPM2sqUR3Xz+o2Vl+2QsXqLsLs=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/c27eff104e0920917c707242e9783c2b.png";
          sha256 = "sha256-Y+t6L4mArzPOtel0QBHxHi2EZTowc6VKKjnBr2dFC1c=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/0c59cdc2503ef2319e9ba065276b46fc.png";
          sha256 = "sha256-pUuQKH9BQW4oUfC6ALrQ8zyPXUHb6NFdyDzw4m3kBw0=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/711dccfb52e41f338d36458ca11cc876.png";
          sha256 = "sha256-PcZf4FP+MwAUp+4ckfCoeoVzdtwOaiD9U3kHU2254hY=";
        };
      };
    };
    DOOM_2 = mkDoom {
      name = "Doom II: Hell on Earth";
      iwad = doom2;
      wad = [ betray ];
      # A separate, standalone Steam app from the unified "DOOM + DOOM II"
      # bundle (appId 2280) used above for WAD extraction; owners of the
      # original get this real app patched with LaunchOptions instead of a
      # synthetic non-Steam shortcut.
      steamAppId = 2300;
      steamCdnImagesHash = "sha256-C7UH5r9SIaMYc9AvJnie/Tdegce9J0etTf6MGvxEhC4=";
    };
    NERVE = mkDoom {
      name = "No Rest for the Living";
      iwad = doom2;
      wad = [ nerve ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/cdb113850d5fd9a6db18a347f3b58d3f.ico";
          sha256 = "sha256-ZhQhsCzwb1jnRsL18FJCGy7t2G7THpMnX9eVhuMmoP8=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/6bb274bf5abf49bc0be27e158efc77ed.png";
          sha256 = "sha256-Q0AdmaKqLcM4bnKm4+rDF3FKt0bjybXzTFQuuIl0RA4=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/dc183c71d625aa2c083399b83e6bee5e.png";
          sha256 = "sha256-+nK9bjjL4v5c0ixHyyF00H4TxTSUSr+C2kst2xGwIOQ=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/8c973b933c53fc43a9b14a712e535eea.png";
          sha256 = "sha256-EWZh3CMwCDaLKgwfAgeUSJh3eudxzOFpZID5Wgx4jr8=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/dd8edf4a5413b7b70fdad591e034ad58.png";
          sha256 = "sha256-HRXW25LU+dHfFltFmFqu4ecyRDIEIYawc2myJ+s+1jo=";
        };
      };
    };
    MASTER_LEVELS = mkDoom {
      name = "Master Levels for Doom II";
      iwad = doom2;
      wad = [ masterLevels ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/0a57a616370cecf60ae96b9ad7bfb19a.ico";
          sha256 = "sha256-hC0kf+s5/DpHp/MrJYDqTGf1G/TgOwkVBCuSO1BP1kg=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/16040d6767ff749d67b892c6d7230ba9.png";
          sha256 = "sha256-F4gfMmzroxVCumuwPXnobVGVrAdAXfnrq5xvPop86Mc=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/39e4973ba3321b80f37d9b55f63ed8b8.jpg";
          sha256 = "sha256-wz5lLsG09IWJPTEl/CyBT5AVlb+nJKb14JrZ0ru4P5o=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/f2e242a63827051ed7ff1ef0f1aa11be.png";
          sha256 = "sha256-T79C/PiN3FS5RIEZ+IqUKOoONuHbISRm8bUlj1fNnr8=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3b247d892477546f83980c789bfb091d.jpg";
          sha256 = "sha256-KcXPVRNjd5eAFeHscZCf3Pw2Y9m9wGtAEelFApbBrXs=";
        };
      };
    };
    SIGIL_I = mkDoom {
      name = "Sigil";
      iwad = doom;
      wad = [ sigil ];
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/efe1051fced36045b29328cfd75c99df.png";
          sha256 = "sha256-Qn2sRhijEb3Ry7vMYl1zL20zsv4wXkD/90BEQq8UkqM=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/d993bcf07adaf448786d6f3cb8a1f995.png";
          sha256 = "sha256-pZsCIph5uiRkG8M+NvE3JcsUkP0d0Cfq7BHnqzqaFoU=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3f7df51fd92a282d6080ad4fe333eb1a.png";
          sha256 = "sha256-s+pBi5RHM4lum/KTrfm8BgnD/PhLlsHoK3TpTRUo0wc=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/b49fdab097253cac48e3dc628a49da5e.png";
          sha256 = "sha256-5As4Hz/a/S3EDGBYUb0OuMNi/0vHb9Pu2SY6evDpJeQ=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/24b52a108051bf2bccd42e44084ffea8.png";
          sha256 = "sha256-tZyfDaWdbqPcXJs1OFokWZ2AFEuyqGAp7bAAepCvt4g=";
        };
      };
    };
    SIGIL_II = mkDoom {
      name = "Sigil 2";
      iwad = doom;
      wad = [ sigil2 ];
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/f47e9d250be8f34ab674e5c0912d3dc1.jpg";
          sha256 = "sha256-BjSevqpsUpQams/YAPAL2ehDnX1uP8WmQrrzAl9xZ/w=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/6e0560ea41c52b69cfcad67d83661b6e.jpg";
          sha256 = "sha256-/Gx+u8ZQAonjN1EirdqD4ycFXBry8OuDjaSptUgoAM4=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/51e7c7c2694254d3ab4d8f9096d9ff40.jpg";
          sha256 = "sha256-dIXz6rag70TzKvL5RuNrr6RYbhcl4No55JfGE0kh9OU=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/d064c4c967d1f451eb48d15e9c257d4f.ico";
          sha256 = "sha256-jTn3+TYVk0kIIu03/MDtkXQjy8Hh/EH6/mPgCxbjbFQ=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/70314ca6c279ed0aa1d108f91c088ca5.png";
          sha256 = "sha256-jKNg7AxJ5MlPXbbADJSLqBfjfQf698xIu9OD5SFpCnE=";
        };
      };
    };
    PLUTONIA = mkDoom {
      name = "The Plutonia Experiment";
      iwad = plutonia;
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/88c03b34bb3d00bab7dbe9fde05e020e.ico";
          sha256 = "sha256-/UrUQcZmivUMrUGbFa8LD3VUv/kfkz6GfKpNFYB+Btg=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/845c36ed2c5d3839518bedb8888ffa54.png";
          sha256 = "sha256-QTfqSqaEEWvrcNgVQ54gnoxxkfAhLgmJiO9BcT4n9Lc=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/d96eed18098da6ab5c15dd856998e4bd.png";
          sha256 = "sha256-WBe2qpXvJ5eG9vAcjFE9h9WZWKyQMjacvrGYOPKjqBY=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/f59eaece9166e041030f29bfa6ac17ad.png";
          sha256 = "sha256-wnE7YuM6SJEFja+4PzLY0ZAaudy8CzmcUY6kKhgIYz4=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/667ea75a7895da024f6298f05f3b658d.png";
          sha256 = "sha256-aNelhZMqnbRZ+TK9zCLvDF9KqDAM2VAzbBg4T7XwRXg=";
        };
      };
    };
    TNT = mkDoom {
      name = "TNT: Evilution";
      iwad = tnt;
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/9438e0bf007d80dda384f1999e4e697a.ico";
          sha256 = "sha256-sXxdmnT/CZqB/RZUtGM5oKRyRP42/Qfl901RhS+eX7w=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/d0840db29ea19e6c1a2b21918c40471e.png";
          sha256 = "sha256-Zr3cRAQr7GnDIt6MsIF99Ts187GMAtXdBcCxiACyyxw=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/19c36b225eb41c36b1fa61c817df1ff3.png";
          sha256 = "sha256-wW4rDw09a+eOJOIn64Ue5E9keU+iyWULAMJPbnvqy8M=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/eb2730e471e458ae4e4fdb83c7402954.png";
          sha256 = "sha256-QXZvQ6jiLDD5kh4EiMN+/UbeFRK5RAZHn9l+doIw7Bw=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/aa6a8423fe25c40bb4dcec8ccf33b0c1.png";
          sha256 = "sha256-v325DFGUOQmXPHzHYaPt5mS160oBkGHYDCZ4KdS6PMI=";
        };
      };
    };
    ID1 = mkDoom {
      name = "Legacy of Rust";
      iwad = doom2;
      wad = [ id1 ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/07a841d9d548265d67ac8897f60f1b06.png";
          sha256 = "sha256-tsPlLmVFdXRyxlaoHG3so2lsSwz4cns57RIWpfsl/n8=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/483d8fc6a9d65675203f340d7ac53ffe.png";
          sha256 = "sha256-ArhZyD3c/T+Dw29LTjZbZbXrZn04usvQofvnDQc7FMA=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3d3078ecfcf9660a6d758f4d49d7c9e8.png";
          sha256 = "sha256-dS1pMxaoKSjK42iOcIOCmssKWLhj47ld0heSYXPwniY=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/e735f72140ffb88c2e7bc478ed25320c.png";
          sha256 = "sha256-NRPQRNogpYjomt2cKRo9RHAC8nPvnejpKcVK7lSn6yY=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/b0ca4cfb576a9a1f9c2957f43f0ad553.png";
          sha256 = "sha256-xyxfsLUIRxJ+a+AZEMMlrPHR8tedA3ZQ//EQJjXsPB0=";
        };
      };
    };

    _masterLevels = {
      disabled = true;
      appId = 9160;
    };
    _doom_i_ii = {
      disabled = true;
      appId = 2280;
    };
  };
}
