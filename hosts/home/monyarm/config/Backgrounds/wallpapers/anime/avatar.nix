{ pkgs, image, ... }:
with image;
{

  toph =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/028/299/285/large/sytokun-aaron-kumar-toph-j.jpg";
      sha256 = "sha256-y9NdACUT8+/z2WAZ90Lpb9u6J4BHA3poMu9AxKLMy0g=";
    }
    |> grow16x9South;
}
