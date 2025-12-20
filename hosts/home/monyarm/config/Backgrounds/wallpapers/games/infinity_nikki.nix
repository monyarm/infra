{ pkgs, ... }:
{
  infinityNikki = pkgs.fetchurl {
    name = "infinity-nikki.jpg";
    url = "https://pbs.twimg.com/media/G7ZLc9AagAApW6_?format=jpg&name=large";
    hash = "sha256-laIqZvm78N9bUeX1eJq/3Dwbu+jz421XTi3iEkrKOfE=";
  };
}
