{ pkgs, ... }:
{
  horizon01 = pkgs.fetchurl {
    url = "https://www.playstation.com/content/dam/global_pdc/en/games/wallpapers/horizon-forbidden-west/horizon-forbidden-west-secondary-keyart-3840x2160-desktop-en-04feb22.jpg";
    sha256 = "sha256-afJP2EOYbO9o1lfuYGhSa/IT6/a50yMpzKhp8GX2Yks=";
  };
  horizon02 = pkgs.fetchurl {
    url = "https://www.playstation.com/content/dam/global_pdc/en/games/wallpapers/horizon-forbidden-west/horizon-forbidden-west-story-keyart-wallpaper-desktop-4k-en-04feb22.jpg";
    sha256 = "sha256-Vh687vS8z4NjFeU4NFlsl1/9/ZW/S0ckvD0+Rf9bx6s=";
  };
}
