{
  pkgs,
  image,
  toWebp,
  ...
}:
with image;
{
  shadowsOfNewYork01 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2020/08/1920x1080.png";
    hash = "sha256-9Cz076R5tDtiDsb0L8yswH5AydeVO7vg6Fkg4TfQydQ=";
  };
  shadowsOfNewYork02 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2020/08/1920x1080-1.png";
    hash = "sha256-O/7kIAiG8bmKNapjxi+LbDX0m6r8r5yPLNH+48i3czo=";
  };
  shadowsOfNewYork03 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2020/08/1920x1080-2.png";
    hash = "sha256-YAwwi4aO0VZTmnqMDXtZIvu1cjo4pB54lDhkTIYTqBQ=";
  };
  shadowsOfNewYork04 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2020/08/1920x1080_sony_2.png";
    hash = "sha256-kNcmHtAIWRWrGoAxLzm8AXdX99qVj6VkZH+FRopxbxE=";
  };
  shadowsOfNewYork05 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2020/08/1920x1080_sony_1.png";
    hash = "sha256-2SVos8wgJSXulXjanedh08ATWr3y11Yk5XcTa5stSEs=";
  };
  coteriesOfNewYork01 =
    "${
      pkgs.fetchzip {
        url = "https://drawdistance.dev/wp-content/uploads/2019/09/Vampire-Wallpaper-Animated.zip";
        hash = "sha256-Mdx/c5MkwWZtp5m/eSCYmj1Qwd9tXazc9SieRK9zeDI=";
      }
    }/Vampire Wallpaper Animated.mp4"
    |> toWebp;
  coteriesOfNewYork02 =
    "${
      pkgs.fetchzip {
        url = "https://drawdistance.dev/wp-content/uploads/2020/01/Vampire-Traffic-Wallpaper.zip";
        hash = "sha256-PpNAk3boFtkR8poN/rlTjn3zEFcrovg7imbr1f+Mb28=";
      }
    }/Vampire Traffic Wallpaper.mp4"
    |> toWebp;
  coteriesOfNewYork03 =
    "${
      pkgs.fetchzip {
        url = "https://drawdistance.dev/wp-content/uploads/2020/01/Vampire-Map-Wallpaper.zip";
        hash = "sha256-LJcYc0R0hBj/DhvHbGA/cIHz7S6PcGFb6TZFgZPs9Ds=";
      }
    }/Vampire Map Wallpaper.mp4"
    |> toWebp;
  coteriesOfNewYork04 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2019/12/Wallpaper_07-1920x1080.jpg";
    hash = "sha256-rMdiC2BFYMLDI+Av1xXiwc9NbsXgh7AXQnFPfofjFoE=";
  };
  coteriesOfNewYork05 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2019/12/Wallpaper_05-1920x1080.jpg";
    hash = "sha256-Py2xQtC9afjcunGi8JZuQyQluw8HVtEtCymRXGcwgfk=";
  };
  coteriesOfNewYork07 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2019/12/Wallpaper_03-1920x1080.jpg";
    hash = "sha256-LHpfRqEQ3cgB6cCiGZXe6BuuP0drQPKtAarchuq54tk=";
  };
  coteriesOfNewYork08 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2019/12/Wallpaper_04-1920x1080.jpg";
    hash = "sha256-kZzykev+/8uhxDINuP66MxzmVYK67swxg1mAlFqtCok=";
  };
  coteriesOfNewYork09 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2019/12/Wallpaper_01-1920x1080.jpg";
    hash = "sha256-3/e86yEbBLXPHA++8+vu0xKTuUPxV/Qo00tUJEoVScA=";
  };
  coteriesOfNewYork10 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2019/12/Wallpaper_08-1920x1080.jpg";
    hash = "sha256-Gjn6LxJ3SAQUnMo3dKexxujJlTOa1KY7Pe7RKJoEDHE=";
  };
  coteriesOfNewYork11 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2019/12/Wallpaper_09-1920x1080-1.jpg";
    hash = "sha256-S9GAueW7f7LydK37I3HnQ5I9HisKNiJrMLmUKlhe+JE=";
  };
  coteriesOfNewYork12 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2019/12/Wallpaper_10-1920x1080-1.jpg";
    hash = "sha256-F/5YN90rXkNmzGMIzpmx/8+UU5rznvg3l8mhQAGLoD4=";
  };
  coteriesOfNewYork13 = pkgs.fetchurl {
    url = "https://drawdistance.dev/wp-content/uploads/2019/12/Wallpaper_11-1920x1080-1.jpg";
    hash = "sha256-vxIZZTxAbDuQ6P/uwmwxN7cAJbzjsb0XNKrd3MoCdZY=";
  };
}
