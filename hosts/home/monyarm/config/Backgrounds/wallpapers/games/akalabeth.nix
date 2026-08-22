{ fetchGOG, getFile, ... }:
{
  akalabeth =
    fetchGOG {
      game = "akalabeth_world_of_doom";
      fileId = 38653;
      sha256 = "sha256-e+Mq/b3JMkk9Sk7Ue7DnLO46UiOEE/dNPNW3ZDyMslY=";
    }
    |> getFile "wallpaper-1920x1080-Akalabeth---World-of-Doom.jpg";
}
