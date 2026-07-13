{
  image,
  fetchPixiv,
  ...
}:
with image;
{
  frieren =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2023/11/14/18/12/54/113403835_p0.jpg";
      sha256 = "sha256-xX+aUMcZMQeM3w8grvhy9iBxrUdnGKCPYLNOqVUbHxs=";
    }
    |> crop16x9;

  frierenNude =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2023/11/14/18/12/54/113403835_p1.jpg";
      sha256 = "sha256-cRjFPGcQ5/8r1G3HmziCOvUzMgX5YZ4HTxqMIdyLXOw=";
    }
    |> crop16x9;
}
