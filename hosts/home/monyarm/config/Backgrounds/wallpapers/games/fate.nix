{
  pkgs,
  image,
  fetchPixiv,
  fetchGelbooru,
  ...
}:
with image;
{
  fateSaber =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/001/405/927/large/liang-xing-10saber.jpg";
      sha256 = "sha256-D11qkN5Myi80vUxbr4nkqv3tFxBS4dZNohqlPFAU3LQ=";
    }
    |> crop16x9North;

  astolfo01 = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/020/439/187/large/welly-thio-astolfo35finalflattencompact.jpg";
    hash = "sha256-+8VRhszUH4abFDNQTYcavIjZ03PJYguMInKEcfFZjq0=";
  };

  astolfo02 =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/11/01/12/44/09/123887424_p0.png";
      sha256 = "sha256-nOAVdcds9MXOArV6cAVMZRCeAy2j6QPJX8UfifkZKu0=";
    }
    |> crop16x9North;

  astolfo03 =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2025/02/16/14/40/27/127309235_p0.png";
      sha256 = "sha256-M/aKJWWGdrlu+B12SOh1TdLcUV++3w4Ip8+2aRqinf8=";
    }
    |> growEdge16x9;

  astolfo04 =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/05/30/13/08/58/119180609_p0.png";
      sha256 = "sha256-QQ6eJqTSFJt7tnYyksPEZHRh5/U4DA6Ld8d1rY4eQto=";
    }
    |> growEdge16x9;

  astolfo05 = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2018/04/14/18/42/08/68225268_p0.jpg";
    sha256 = "sha256-njRdmNwxIm/UnpNs9G9c9ZIatjcYtfmBrutBh4FmWiA=";
  };

  # astolfo06 is a mirror for https://x.com/tatsunoue3229/status/886920922128461824 because the account has been deleted
  astolfo06 = fetchGelbooru {
    url = "https://img4.gelbooru.com/images/d7/2a/d72a8ff8d13ca0fdb0631e1b3f995c20.jpg";
    hash = "sha256-yhQPA+Zpsk6PISkb5IJkdLUjj/WfuiVTdCB3hqZs7FM=";
  };

  astolfo07 = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2019/07/28/19/12/41/75954573_p0.png";
    sha256 = "sha256-7u357KZbrRHBNF6hwxrE1+O445qI3MJrW7ZLHxSDydI=";
  };

  astolfo08 = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2018/08/10/01/15/29/70116820_p0.png";
    sha256 = "sha256-T6NwzZdRNdtDlNAyYWICcOIsVaLE90ehE07tS9cDi+I=";
  };
}
