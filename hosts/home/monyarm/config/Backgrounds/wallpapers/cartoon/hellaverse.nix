{ pkgs, image, ... }:
with image;
let
  cutHalf =
    gravity:
    transform {
      args = "-gravity ${gravity} -crop 100%x50%+0+0";
    };
  grimmieCouples = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/Ge7428zaUAA1jFS?format=jpg&name=4096x4096";
    name = "grimmie-couples.jpg";
    sha256 = "sha256-eaU4DEulZCxubXl1rgpwm/KAkhcELyBliybuNky3ppg=";
  };
in
{
  grimmieCouples01 = grimmieCouples |> cutHalf "north" |> crop16x9;
  grimmieCouples02 = grimmieCouples |> cutHalf "south" |> crop16x9;
}
