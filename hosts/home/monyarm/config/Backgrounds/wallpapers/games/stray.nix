{ pkgs, ... }:
{
  stray = pkgs.fetchurl {
    url = "https://www.playstation.com/content/dam/global_pdc/de-de/games/wallpapers/Stray-1-de-3840x2160-11jul22.jpg";
    sha256 = "sha256-2kGAAQDjaOgdMShEt0RNgjjqv6YDUcA5GprBmbBjDPs=";
  };
}
