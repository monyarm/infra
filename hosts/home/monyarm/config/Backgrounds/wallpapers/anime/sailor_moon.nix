{
  pkgs,
  image,
  fetchPixiv,
  ...
}:
with image;
{
  amiBeach =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/09/10/00/05/01/122295377_p0.jpg";
      sha256 = "sha256-8ierVF8rLcJANPDlOTmLhQANgNMy9UhHgN5KCqXnqy4=";
    }
    |> crop16x9North;

  reiBow =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/04/17/11/49/49/117913427_p0.jpg";
      sha256 = "sha256-SY/sTtui9AOwaOIbDhmY/NfFkMNKNzIEi8BmUF5PL18=";
    }
    |> crop16x9North;

  sailorSenshi01 = pkgs.fetchurl {
    name = "sailorSenshi01.jpg";
    url = "https://pbs.twimg.com/media/GFCD1pca0AA3Gha?format=jpg&name=large";
    sha256 = "sha256-tYT6D3vs89BhY6Ktf9I0TGT27pzB9XXeX5e95Kt4MoQ=";
  };
}
