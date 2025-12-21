{
  pkgs,
  image,
  toWebp,
  ...
}:
with image;
{
  infinityNikki = pkgs.fetchurl {
    name = "infinity-nikki.jpg";
    url = "https://pbs.twimg.com/media/G7ZLc9AagAApW6_?format=jpg&name=large";
    hash = "sha256-laIqZvm78N9bUeX1eJq/3Dwbu+jz421XTi3iEkrKOfE=";
  };
  infinityNikki01 = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GRunx9UasAECEad?format=jpg&name=4096x4096";
    hash = "sha256-BSUqzv6Wsok+Eg604cMuEeI8I59fX8i85W+mn2coNO4=";
    name = "infinity-nikki-1.jpg";
  };

  infinityNikki02 = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GRunx9SaAAEoDPY?format=jpg&name=4096x4096";
    hash = "sha256-/Weq1A0lB3GKGf2T456mfWOWjHLto0KCx+QRQWQcSyI=";
    name = "infinity-nikki-2.jpg";
  };

  infinityNikki03 = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GRpkubcaUAIZyoo?format=jpg&name=4096x4096";
    hash = "sha256-k3jke2u48Eexx+ceMlm16YYcmS6mMiVffFDv/5W+s60=";
    name = "infinity-nikki-3.jpg";
  };

  infinityNikki04 = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GRpkubbbMAEcNh8?format=jpg&name=4096x4096";
    hash = "sha256-sDpwZpMQWhqYe84s2ExycQ+TS4fzRGm8F+KKHIws2PM=";
    name = "infinity-nikki-4.jpg";
  };

  infinityNikki05 = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GRkT2CmWMAEeRa6?format=jpg&name=4096x4096";
    hash = "sha256-Fl6YAJNB89oSbpNqcfo/n+Vrz1Zir6us/9qoqZhvQYs=";
    name = "infinity-nikki-5.jpg";
  };

  infinityNikki06 = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GRkT2CqWUAA9GyU?format=jpg&name=4096x4096";
    hash = "sha256-0bNgreoHFkzYXDBo9k+KU6sXVSjtQa657KBXu1Ur6jY=";
    name = "infinity-nikki-6.jpg";
  };

  infinityNikki07 =
    pkgs.fetchurl {
      url = "https://wx1.sinaimg.cn/mw2000/008d1pldgy1hgjl8xod74j34mo334e8k.jpg";
      hash = "sha256-qYm9lXQz2VNocr0h190wzMc6NrutCHVzkhjH1Eh0jfg=";
    }
    |> crop16x9North;

  # Mirror for https://www.weibo.com/7521490767/NciQz6jZF
  infinityNikki08 =
    pkgs.fetchurl {
      url = "https://cdn.donmai.us/original/f6/5e/__ad_lunam_nikki_and_1_more__f65e3843c41af7d9aba8e0937bc9f8c8.mp4";
      hash = "sha256-SC/ehXwDc3hx+W07PK8Az1VeUey1zZYPc8Ft9uubyyc=";
      name = "infinity-nikki-video.mp4";
    }
    |> toWebp;
}
