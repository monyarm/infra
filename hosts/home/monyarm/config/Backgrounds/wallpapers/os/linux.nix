{ pkgs, ... }:
{

  gentooCow = pkgs.fetchurl {
    url = "https://www.gentoo.org/assets/img/wallpaper/gentoo-cow/gentoo-cow-gdm-remake-1920x1080.png";
    sha256 = "sha256-q3dCTy7r/ng2jhu1+EHpJJxXGqR/kj0siWC0RDkY5ig=";
  };
}
