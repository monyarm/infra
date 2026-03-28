{ pkgs, toWebp, ... }:
{
  museRadio =
    pkgs.fetchurl {
      url = "https://cdn.akamai.steamstatic.com/steamcommunity/public/images/items/774171/fadd8bc9ccf0ac84881c83dd32812004d7d54e14.mp4";
      hash = "sha256-K+FkSCzRV7XVbM9YpsZaF0FnKoRIugqPiUoqnv9jkvA=";
    }
    |> toWebp;
}
