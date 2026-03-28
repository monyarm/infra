{ pkgs, image, ... }:
with image;
{
  kpopDemonHuntersGroup = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/093/971/043/large/kiko-l-jason-liang-k-pop-demon-hunters.webp";
    sha256 = "sha256-UH8TRqAtfn4GdYHvU9WU5jB4ze08IJtoB6cvFrrVg0Q=";
  };
}
