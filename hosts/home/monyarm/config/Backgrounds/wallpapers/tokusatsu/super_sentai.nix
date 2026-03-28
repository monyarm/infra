{
  fetchPixiv,
  image,
  pkgs,
  ...
}:
with image;
{
  garyudo = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/07/26/13/49/44/133129230_p0.jpg";
    sha256 = "sha256-D9j4EzR+Xyqh9/AxQ8DEjglo1FAHL3wslgeGeyhIKTQ=";
  };

  gozyuUnicorn = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/03/16/12/43/36/128269525_p1.jpg";
    sha256 = "sha256-NSGZHbNOziO57KrxpecS80KHWH4f3/uKB9utESLh1us=";
  };

  zyuRangerGroup =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/020/638/160/large/anthony-ray-zyuranger-resize.jpg";
      sha256 = "sha256-JjbUYQZWVJAGUw6Ni93B5sfibvoMk8m2YUM2BhG0k+c=";
    }
    |> grow16x9;

  donDragoku =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/051/571/467/large/samcy-.jpg";
      sha256 = "sha256-my6C47X41iBGnbrOBla8u0xgTBkamOtmJW4mKdbJL+w=";
    }
    |> crop16x9South;

  kuwagataOhger =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/061/630/795/large/samcy-.jpg";
      sha256 = "sha256-t2FsQNLBN6EtSee3c5VpYtPQ76qIGnHdGpGxXU1UP8I=";
    }
    |> crop16x9;

  tomboOhger =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/061/630/811/large/samcy-.jpg";
      sha256 = "sha256-Dy0ahMA1nH8l62tJpOwHxtknWbcJKFF/EE6i6LiNPLg=";
    }
    |> crop16x9;

  kamakiriOhger =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/061/630/831/large/samcy-.jpg";
      sha256 = "sha256-++7B12aVaXIbmqPSc/41OxL2zoN+ij0nWWdG5MGUzB0=";
    }
    |> crop16x9;

  hachiOhger =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/061/630/843/large/samcy-.jpg";
      sha256 = "sha256-DWaVviJKdPnxAI/PxXgLhucn+RP29DppsdaZyvvHwCY=";
    }
    |> crop16x9;

  papillonOhger =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/061/630/865/large/samcy-.jpg";
      sha256 = "sha256-Qi5MbRq19hld5+Tw1jD8n7SCoTcWQZHHEEzRIcAO6Zk=";
    }
    |> crop16x9;

  donbrothers = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2022/05/01/00/00/19/98000865_p0.png";
    sha256 = "sha256-1IXSofyCAgakmi42YFReyNfMo/+z0viT/fMkO2XBlvY=";
  };
}
