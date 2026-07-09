{
  pkgs,
  image,
  fetchGelbooru,
  ...
}:
with image;
let
  grimmieCouples = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/Ge7428zaUAA1jFS?format=jpg&name=4096x4096";
    name = "grimmie-couples.jpg";
    sha256 = "sha256-eaU4DEulZCxubXl1rgpwm/KAkhcELyBliybuNky3ppg=";
  };
in
{
  grimmieCouples01 = grimmieCouples |> cutHalf "north" |> crop16x9;
  grimmieCouples02 = grimmieCouples |> cutHalf "south" |> crop16x9;

  luciferNtti = pkgs.fetchurl {
    name = "luciferNtti.jpg";
    url = "https://pbs.twimg.com/media/G8KSoR0bIAAwrRi?format=jpg&name=4096x4096";
    hash = "sha256-P2Q1Ty824TXBHyLvW6bTqqI3Kr8Ctpq8M/DkeSbyU2Q=";
  };

  velvetteBikini =
    pkgs.fetchurl {
      url = "https://64.media.tumblr.com/3987bac65acb1b31abb1b1f8431ba618/ef8a48263093a10e-d0/s1280x1920/1aa7d26893c2042b778b034b4c6d2f957b62b675.jpg";
      hash = "sha256-n2Blgyu5iGObau0h0kV4gkdOUPBQTTClnr/5dXG0ddA=";
    }
    |> crop16x9North;

  luteWing =
    pkgs.fetchurl {
      name = "luteWing.jpg";
      url = "https://pbs.twimg.com/media/G8tZ2VQXYAANeg4?format=jpg&name=large";
      hash = "sha256-ZIQr3gx2FOIZD41HesuhmYxwylv0TtLH8ziXcn0QprE=";
    }
    |> crop16x9North;

  charlieNomifae =
    pkgs.fetchurl {
      name = "charlieNomifae.jpg";
      url = "https://pbs.twimg.com/media/G8dtWacXAAA-fEt?format=jpg&name=large";
      hash = "sha256-iOjzn0Wbu2MEIZ+jk9Sy2yry7gewWwmJC6cVCdcs6HM=";
    }
    |> grow16x9;

  charlieVaggieUrban =
    pkgs.fetchurl {
      name = "charlieVaggieUrban.jpg";
      url = "https://pbs.twimg.com/media/G8jCC3RawAE3t1U?format=jpg&name=4096x4096";
      hash = "sha256-1Ojjw2CglB54u0A34cQ9s21OojycNlaJRbC+FRJWnh8=";
    }
    |> crop16x9North;

  rosieAlastor = pkgs.fetchurl {
    name = "rosieAlastor.jpg";
    url = "https://pbs.twimg.com/media/G8iNtzeasAATrWC?format=jpg&name=large";
    hash = "sha256-tHN0FiK6ctDVdpJDBdLRiLyNOR8F69Z8m77LR34QuH0=";
  };

  paimon =
    pkgs.fetchurl {
      name = "paimon.jpg";
      url = "https://pbs.twimg.com/media/FVrgeaUUsAECjSZ?format=jpg&name=large";
      hash = "sha256-hfKzUoAODouDqQTILiN6hLzh+ARn2LycZP1jGXK9UB4=";
    }
    |> crop16x9South;

  # stolas01 is a mirror of https://huayin449.lofter.com/post/1f201d79_2b5b8a562
  stolas01 =
    fetchGelbooru {
      url = "https://img4.gelbooru.com/images/c3/3c/c33c532af73d84aa7d6d29fc03a00752.png";
      hash = "sha256-aOUiS+/ef8TqfRazXnG7uV6AIxk6WQiHIqFt3jXbze4=";
    }
    |> crop16x9West;

  # stolas02 is a mirror of https://huayin449.lofter.com/post/1f201d79_2b5be49bc
  stolas02 =
    fetchGelbooru {
      url = "https://img4.gelbooru.com/images/af/8c/af8c7db9d2e9ea54f26c9fd5ad86aee4.jpg";
      hash = "sha256-PrVdNi5djCn4jzBFb110sXACDcobE2/KdbpI0vn/fQM=";
    }
    |> crop16x9West;
}
