{ pkgs, image, ... }:
with image;
{
  sytokunAcademyRWBY =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/038/695/750/large/sytokun-aaron-kumar-remnant-academy-rwby.jpg";
      sha256 = "sha256-swfR/rX2XuMX9V+vTFkscODcD1VbikCvETIwHWov/eY=";
    }
    |> removeBackground {
      coordinates = [
        {
          x = 1889;
          y = 935;
        }
      ];
      fuzz = 7;
    }
    |> grow16x9South' "white";

  rubyRoseCloak = pkgs.fetchurl {
    url = "https://cdna.artstation.com/p/assets/images/images/036/032/978/large/sytokun-aaron-kumar-wath-rubycloak-res-notitle.jpg";
    sha256 = "sha256-VVNqD8cVVE0o9lwB5g1K3tzqQunvuaJAlr1PKyKsVDw=";
  };

  rubyYang = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/031/278/787/large/sytokun-aaron-kumar-low-10-res.jpg";
    sha256 = "sha256-YGREvg5EC9MSzfHbhBU2O90STjZYGQMRpVoEiAo4YYA=";
  };
}
