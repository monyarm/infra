{ image, fetchPixiv, ... }:
with image;
{
  flagBearer =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2025/05/29/20/33/39/130945370_p0.png";
      sha256 = "sha256-qj8TOY/ixnM+bPQ+lWUIN3LVakv0AM1ntTn7rw2dH5k=";
    }
    |> crop16x9;

  femDiver =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/06/06/23/36/42/119405466_p0.jpg";
      sha256 = "sha256-+7nDjnZXTK1zTY2RXO80eS3EhSMcovc2Xz/NWIResFI=";
    }
    |> crop16x9;

  femDiverHelmet =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/06/06/23/36/42/119405466_p1.jpg";
      sha256 = "sha256-DXhqvbrsDNiXDge/lPIY8kEC29rODojvhkzXgnD5Vjs=";
    }
    |> crop16x9;

  femDiverGroup =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/06/27/21/28/34/120025419_p1.jpg";
      sha256 = "sha256-MHGsfEgBMR35ET3HufzLO2lohqOFoJ/A8YKQAq9aC0Q=";
    }
    |> crop16x9;

  femDiverGroupHelmet =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/06/27/21/28/34/120025419_p0.jpg";
      sha256 = "sha256-iXBeoXK7YPB08WQ13WXQAq5YtBs1SrJLuybvL2pBE+0=";
    }
    |> crop16x9;

  isThisDecisionFromTheTop =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/05/07/21/52/21/118527886_p0.jpg";
      sha256 = "sha256-YYSkKs1AxlE9UBgDFh/Vi9tNQN5OI9dMDuu0bL4VV3E=";
    }
    |> crop16x9;

  femDiverFireFight =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/04/21/23/19/20/118049051_p0.jpg";
      sha256 = "sha256-iI8DBWg65Rqn6sZkaYyuf7NZauHIED7+fYEfIfgRxBE=";
    }
    |> crop16x9West;

  femDiverCloneGroup =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/04/07/23/05/28/117644354_p1.jpg";
      sha256 = "sha256-gI4gCVplbHagQQGAAeJfZlENeaLttqviQKdm7O7ispw=";
    }
    |> crop16x9;
}
