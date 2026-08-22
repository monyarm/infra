{ fetchGOG, getFile, ... }:
{
  fearPlatinum =
    fetchGOG {
      game = "fear_platinum";
      fileId = 40363;
      sha256 = "sha256-xqKsHMWzf6qD4qiDD7burX3Dpy5rcbPU78nP2sjadBc=";
    }
    |> getFile "wallpaper-2560x1440-F.E.A.R..jpg";
}
