{ pkgs, image, ... }:
with image;
{
  himikoOchako =
    pkgs.fetchurl {
      name = "himikoOchako.jpg";
      url = "https://pbs.twimg.com/media/GiEV7y0bwAA3vIz?format=jpg&name=4096x4096";
      sha256 = "sha256-itbrAgc4HTV4IEf7wUeNwJiw2/CR30oiniHQAS4PTx8=";
    }
    |> crop16x9;
}
