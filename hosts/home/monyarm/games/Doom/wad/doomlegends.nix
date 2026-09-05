{
  config,
  pkgs,
  lib,
  getFile,
  mkDoom,
  ...
}:
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    tucq =
      let
        version = "6";
      in
      pkgs.fetchzip {
        url = "http://www.doomlegends.com/chexquest/TUCQR${version}.zip";
        sha256 = "sha256-AulxYjl2o/M2zCTe9H5mvMk/2BZ5iigBo9+0iIIpC28=";
        stripRoot = false;
      }
      |> getFile "TUCQR${version}.WAD";

    cqstrife =
      let
        version = "6";
      in
      pkgs.fetchzip {
        url = "http://www.doomlegends.com/chexquest/cqstrifeR${version}.zip";
        sha256 = "sha256-pkVx11rO+1DH5AY88sjbesxH2EVRgXXUkOcUcSXhCyc=";
        stripRoot = false;
      }
      |> getFile "cqstrifeR${version}.wad";
  };

  programs.steam.games = with config.games.doom.wads; {
    TUCQ = mkDoom {
      name = "The Ultimate Chex Quest";
      iwad = tucq;
      wad = [ cqstrife ];
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/3a4496776767aaa99f9804d0905fe584.ico";
        sha256 = "sha256-nlPmXmb+CtQ5sCY5fjfeFYbIfV8nQx67Qo0XIe3iU/o=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/d4db78e389387c2d6f0b5404cbc61fc5.png";
        sha256 = "sha256-92HdMdR5E7dpZXZphWucz9IaAO2r0o/t1ZZzS+8shEc=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/9188905e74c28e489b44e954ec0b9bca.png";
        sha256 = "sha256-mWoVOahfLMYEPDHzz+tXse3kJsCDT7TJfQBeZXmKOK4=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/15e4e84f7d87333928bc407a87414223.png";
        sha256 = "sha256-FaqI46W2Bsc/Lso2+Ymnuj9mJUzfW8vlOJTy8L+m4XE=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/6f8caa0e6413027cb7a12f945151cb8d.png";
        sha256 = "sha256-eN6P9Wsln1Wqal/JGlhKnVzvN+Q6+xdA9qmuZcg0fxI=";
      };
    };
  };
}
