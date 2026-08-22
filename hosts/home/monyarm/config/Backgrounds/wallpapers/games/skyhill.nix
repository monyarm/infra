{
  fetchGOG,
  getFile,
  image,
  ...
}:
with image;
{
  skyhill =
    fetchGOG {
      game = "skyhill";
      fileId = 69123;
      sha256 = "sha256-koOJaaEZezKM68f2g74+amxgsc/urjv3iNFFDkQKkgo=";
    }
    |> getFile "skyhill_wallpaper/wallpaper_skyhill.jpg"
    |> crop16x9East;
}
