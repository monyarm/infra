{
  image,
  fetchPixiv,
  ...
}:
with image;
{
  twins = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2023/02/23/22/36/50/105649426_p0.jpg";
    sha256 = "sha256-FW8rOdBc13B1ICmP2nnW/9HGw8kJxUQONN7y2P0XTig=";
  };
}
