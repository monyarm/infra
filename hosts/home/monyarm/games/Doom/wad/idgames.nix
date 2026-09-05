{
  config,
  lib,
  pkgs,
  getFile,
  fetchIdGames,
  mkDoom,
  sources,
  ...
}:
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    paranoid = fetchIdGames sources.wad.paranoid |> getFile "Paranoid.pk3";
    paranoiac = fetchIdGames sources.wad.paranoic |> getFile "paranoic.pk3";
    aoddoom = fetchIdGames sources.wad.aoddoom |> getFile "aoddoom2.wad";
    aoddoomDeh = fetchIdGames sources.wad.aoddoom |> getFile "aoddoom2.deh";

    actionDoom2 = fetchIdGames sources.wad.actiondoom2 |> getFile "action2.wad";
    pirateDoom = fetchIdGames sources.wad.piratedoom |> getFile "Pirates!.wad";
    batmanWad = fetchIdGames sources.wad.batmandoom |> getFile "batman.wad";
    batmanDeh = fetchIdGames sources.wad.batmandoom |> getFile "batman.deh";
    inquisitor = fetchIdGames sources.wad.inquisitor |> getFile "inqstr.wad";
    inquisitor2 = fetchIdGames sources.wad.inquisitor2 |> getFile "inqstr2e.wad";
    inquisitor3Res = fetchIdGames sources.wad.inquisitor3 |> getFile "inq3resE.pk3";
    inquisitor3Wad = fetchIdGames sources.wad.inquisitor3 |> getFile "inqstr3e.wad";
  };

  programs.steam.games = with config.games.doom.wads; {
    paranoid = mkDoom {
      name = "Paranoid (Half-Life)";
      iwad = paranoid;
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/1ff70043c78f44fc8841bd8203c00ed3.jpg";
          sha256 = "sha256-5JGFeSPTHQcjitRKv23+aGs4UVuoQLjM3NPe7skbMe0=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/2867b8b75a9cf35a537e57ce87ed02d4.png";
          sha256 = "sha256-bwqxo/o+9wfcbiKhJUXsXVB8zwRGNufvP7d6bpJ3OCw=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/1b00ba05ce41c38bb3ea6a142270fa22.png";
          sha256 = "sha256-T6lCU+iDQXbeGwbXjOAycEAapkygWTtjWo8h6bOMkUY=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/6dfbcb8172dbfca2e94b3ec9a99789a5.png";
          sha256 = "sha256-gv1Q90M+0UL+uL9hHvyVZMtayAZ5gWacu2NXjxiIftA=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/ea91017461fb6e2cd08664ad2263c699.png";
          sha256 = "sha256-9K6e5yPhn5JhNs3gXda084mL2SPy5SuwTd23DLRp/wU=";
        };
      };
    };
    Paranoiac = mkDoom {
      name = "Paranoiac";
      iwad = paranoid;
      wad = [ paranoiac ];
    };
    aoddoom = mkDoom {
      name = "Army of Darkness Doom";
      iwad = aoddoom;
      wad = [ aoddoomDeh ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/6f39e30f49a56af52ae983e23dee9b12.ico";
          sha256 = "sha256-1ZxoTzXL/Ke5JKfWrl48TW77gLeanZCZme/FqIvVpS0=";
        };
      };
    };

    ActionDoom2 = mkDoom {
      name = "Action Doom 2: Urban Brawl";
      iwad = actionDoom2;
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/46901464146c21c867631e55cb96f93a.png";
          sha256 = "sha256-c4hYcVPgN519O3G5oRY10zNgXIsA6AKGa8/NRFLW32c=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/c5a8081a0b50c262305021e892eec570.png";
          sha256 = "sha256-alxRPZ4AvHF+6HjKoxeToILRlt5XnGXQzYuI51eq3IE=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/f6624d9e89c50bfc372d18455649a5c3.png";
          sha256 = "sha256-SrVq2lHVvG1u9BzyMyNPpPAt1h0gllft+nVmjhdFp3U=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/7399a8aa203c68565ff7196769deadc6.png";
          sha256 = "sha256-OYpVm3gjMvxwnJVs4IgtUzzZPj2Hg9qPwhuaLu9W34U=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/0eb178c5581f651876fadae5a8980899.png";
          sha256 = "sha256-HXrRO+MU95YphaXH7BXMXb3/ZcLUs19K6+RPdDjSBKo=";
        };
      };
    };
    PirateDoom = mkDoom {
      name = "Pirate Doom";
      iwad = doom2;
      wad = [ pirateDoom ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/9887aaeef10b0ca9186f12ed7315d4bb.ico";
          sha256 = "sha256-G17sLmWKzVKJDH6DjpiZN0kwGltn2IaDA0QPjxwI0fM=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/58f8bc35cb0d2623ed4720711c3fa696.png";
          sha256 = "sha256-yxcKGTPuJn7mVH6Od9GFA4x9cSQqenKZlYxPcdwY0YM=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/70515a2dc22fc2fa3af4b5f7d1aa0d98.png";
          sha256 = "sha256-X2mY/BG7guKhJ85zfVSWQmuoPA/lyrw1HwEVTZ4fiK8=";
        };
      };
    };
    BatmanDoom = mkDoom {
      name = "Batman Doom";
      iwad = doom2;
      wad = [
        batmanWad
        batmanDeh
      ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/258c6d264db9832bf14eec8b82d95477.png";
          sha256 = "sha256-zzfl9ZkkWO29UpyrgPvpzDvFfBhL0dHxbB+dc1l3vlc=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/c6bc593c79df94f43ffed8fce7a43c0c.png";
          sha256 = "sha256-fXBTdPCKk/8f03QlNo6JJqtd6dRk/WxXZG/tOMEFQAE=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/9b2033bd267debdc3dd860046f94580a.png";
          sha256 = "sha256-j5OuwLDM38+PrjvfmiIBRP8BARFWeAnZ5TG8V+msKKQ=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/30839b54641c2622c27a9f2db83827a1.png";
          sha256 = "sha256-BuJLNGnqtvqOEFJaYQGcER5sdcyECF9+8DmFt6eul8M=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/c534e2f89539e866011e1e75adfefbfb.jpg";
          sha256 = "sha256-LOANWqx5npt/1TQG3HLHUpM+2x+BL4QcP0YFyeYqDgQ=";
        };
      };
    };
    Inquisitor = mkDoom {
      name = "The Inquisitor";
      iwad = doom2;
      wad = [ inquisitor ];
    };
    Inquisitor2 = mkDoom {
      name = "The Inquisitor 2";
      iwad = doom2;
      wad = [ inquisitor2 ];
    };
    Inquisitor3 = mkDoom {
      name = "The Inquisitor 3";
      iwad = doom2;
      wad = [
        inquisitor3Res
        inquisitor3Wad
      ];
    };
  };
}
