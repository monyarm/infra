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
      sha256 = "sha256-e+2MsE9F9gmj5QLrILtPUU/M7wiuyZ/CM2T7wVYr29w=";
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
      sha256 = "sha256-wTYU/KJ9T+IlPke9/IbYmZ7sl+z62/xgr45HwaRtKZs=";
    }
    |> crop16x9;

  tomboOhger =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/061/630/811/large/samcy-.jpg";
      sha256 = "sha256-/+Of6knnWz+efmIf8C4E+GRMBzAUJDtMgyWzkxjoSGI=";
    }
    |> crop16x9;

  kamakiriOhger =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/061/630/831/large/samcy-.jpg";
      sha256 = "sha256-+kZA6ZAmHg7S0SY5ZDBFeEKYK3prXOELEoLVCbXPmmQ=";
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
      sha256 = "sha256-F0HlrWB6pODN+7iPtu2rhWtiYI4biKpzdubDonpJMU8=";
    }
    |> crop16x9;

  donbrothers = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2022/05/01/00/00/19/98000865_p0.png";
    sha256 = "sha256-1IXSofyCAgakmi42YFReyNfMo/+z0viT/fMkO2XBlvY=";
  };
}
