{ pkgs, image, ... }:
with image;
{
  fateSaber =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/001/405/927/large/liang-xing-10saber.jpg";
      sha256 = "sha256-D11qkN5Myi80vUxbr4nkqv3tFxBS4dZNohqlPFAU3LQ=";
    }
    |> crop16x9North;
}
