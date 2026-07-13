{ pkgs, ... }:
{
  bayonetta01 = pkgs.fetchurl {
    name = "bayonetta01.jpg";
    url = "https://pbs.twimg.com/media/GX4kPdNaUAAMhQ4?format=jpg&name=large";
    sha256 = "sha256-f0MwyglVTARj8lZebeu+5GAteXK15wk0dYLPezgA0JE=";
  };
}
