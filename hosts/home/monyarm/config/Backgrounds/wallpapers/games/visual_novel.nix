{ pkgs, ... }:
{
  the-key-to-home = pkgs.fetchurl {
    url = "https://media.rawg.io/media/resize/1920/-/screenshots/4ed/4eda4f7188b6e506c239ba0b22e8a87b.jpg";
    hash = "sha256-Rs5VUQBtxMkYaajG9/tO48YJjBfu9cXpLoS/NuUFQAA=";
  };

  # Mirror for http://hadashi.product.co.jp/gallery/image/201312a.png
  threePingLoversLoloEdwarRumines = pkgs.fetchurl {
    url = "https://cdn.donmai.us/original/fa/00/__lolo_edwar_and_rumines_3ping_lovers_drawn_by_sakagami_umi__fa00ab93dc2c610470e6e68bb3ef9af7.png";
    hash = "sha256-pzNEVV88bodmzl90jkbF0ZtzQvtEAYdR7vWGLohwVw0=";
  };

  # Mirror for http://hadashi.product.co.jp/gallery/image/201312b.png
  threePingLoversFrayRinggitAliceErzan = pkgs.fetchurl {
    url = "https://cdn.donmai.us/original/47/43/__fray_ringgit_and_alice_erzan_3ping_lovers_drawn_by_ino_magloid__4743f832d13bfdfbbc539e2f2a4d4a90.png";
    hash = "sha256-NOlm+4lAe6gJLSLdg4GeqODh9d0AWhXouDHPPk4PWdI=";
  };
}
