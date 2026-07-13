{
  image,
  fetchPixiv,
  ...
}:
with image;
{
  ophelia =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2025/11/26/21/42/38/137924001_p0.png";
      sha256 = "sha256-CpZia1xdWg32mQ4zcVr+rOcU1zYY+o8nn4nvXVr58PI=";
    }
    |> crop16x9North;
}
