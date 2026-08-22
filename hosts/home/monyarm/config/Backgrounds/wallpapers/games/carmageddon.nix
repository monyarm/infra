{ fetchGOG, getFile, ... }:
{
  carmageddon =
    fetchGOG {
      game = "carmageddon_max_pack";
      fileId = 15693;
      sha256 = "sha256-rkwIN+PfFl4cGqxobBGzQnS8j3HxqQpjVZU7f2FdVgo=";
    }
    |> getFile "wallpaper/wallpaper01_1920x1080-Carmageddon.jpg";
}
