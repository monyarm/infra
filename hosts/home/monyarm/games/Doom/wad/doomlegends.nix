{
  config,
  getFile,
  fetchzipNoSubst,
  mkDoom,
  ...
}:
{
  games.doom.wads = {
    tucq =
      let
        version = "6";
      in
      fetchzipNoSubst {
        url = "http://www.doomlegends.com/chexquest/TUCQR${version}.zip";
        sha256 = "sha256-AulxYjl2o/M2zCTe9H5mvMk/2BZ5iigBo9+0iIIpC28=";
        stripRoot = false;
      }
      |> getFile "TUCQR${version}.WAD";

    cqstrife =
      let
        version = "6";
      in
      fetchzipNoSubst {
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
    };
  };
}
