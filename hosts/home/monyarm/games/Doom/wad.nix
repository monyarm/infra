{
  pkgs,
  lib,
  getFile,
  fetchzipNoSubst,
  ...
}:
let

  mkDoom =
    {
      iwad,
      wads ? [ ],
      ...
    }@args:
    (lib.removeAttrs args [
      "iwad"
      "wads"
    ])
    // {
      game = pkgs.uzdoom;
      args = ["-iwad ${iwad}"]
      ++ (lib.optionals (wads != null && wads != [ ]) (map (w: "-file ${w}") wads));

    };

  wads = {
    TUCQR6 =
      fetchzipNoSubst {
        url = "http://www.doomlegends.com/chexquest/TUCQR6.zip";
        sha256 = "sha256-AulxYjl2o/M2zCTe9H5mvMk/2BZ5iigBo9+0iIIpC28=";
        stripRoot = false;
      }
      |> getFile "TUCQR6.WAD";
  };

in
{
  programs.steam.games = {
    TUCQ = mkDoom {
      name = "The Ultimate Chex Quest";
      iwad = wads.TUCQR6;
    };
  };
}
