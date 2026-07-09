{ pkgs, image, ... }:
with image;
{
  kpopDemonHuntersGroup = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/093/971/043/large/kiko-l-jason-liang-k-pop-demon-hunters.webp";
    sha256 = "sha256-UH8TRqAtfn4GdYHvU9WU5jB4ze08IJtoB6cvFrrVg0Q=";
  };

  kpopDemonHuntersGroup02 =
    pkgs.fetchurl {
      name = "kpopDemonHuntersGroup02.jpg";
      url = "https://pbs.twimg.com/media/G_XLog5X0AAWE5V?format=jpg&name=4096x4096";
      hash = "sha256-EpIw54eF0ACkdOyXLTmJDh5vxcmaO9lrlGwIkBgpeYY=";
    }
    |> crop16x9;

  kpopDemonHuntersGroup03 =
    pkgs.fetchurl {
      name = "kpopDemonHuntersGroup03.jpg";
      url = "https://pbs.twimg.com/media/GzDKE0RWsAAZpgx?format=jpg&name=large";
      hash = "sha256-aUhGba+wKb3vxJClwd+d8tTCw7GUV8O1Z9o1RZYoE1A=";
    }
    |> crop16x9;

  kpopDemonHuntersGroupCyberpunk =
    pkgs.fetchurl {
      name = "kpopDemonHuntersGroupCyberpunk.jpg";
      url = "https://pbs.twimg.com/media/Gv_LKyKaUAA-6rv?format=jpg&name=large";
      hash = "sha256-o9AHM158HkNbUR/DdVFV3q5pbfa/4AXDSoOiCB936dY=";
    }
    |> crop16x9North;

  kpopDemonHuntersGroup04 =
    pkgs.fetchurl {
      name = "kpopDemonHuntersGroup04.jpg";
      url = "https://pbs.twimg.com/media/GwERdKbagAAyedO?format=jpg&name=4096x4096";
      hash = "sha256-+BF6EtSpJ529GtYytfUfH1+1pM1X/LXvGHi7P4ZRHq4=";
    }
    |> crop16x9North;

  kpopDemonHuntersGroup05 =
    pkgs.fetchurl {
      name = "kpopDemonHuntersGroup05.jpg";
      url = "https://pbs.twimg.com/media/Gt-a3ClWMAAKXui?format=jpg&name=large";
      hash = "sha256-BNlvwAtYxGzx0tNkvsViGVdO49b6wamOC73aN3ETalY=";
    }
    |> crop16x9North;
}
