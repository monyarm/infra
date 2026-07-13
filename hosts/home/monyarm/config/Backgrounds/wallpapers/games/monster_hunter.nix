{
  image,
  fetchPixiv,
  ...
}:
with image;
{
  diva =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2025/04/06/20/00/26/129027263_p0.png";
      sha256 = "sha256-sfrb5t5xYTbvGdK5LDAWtQ3/eqquOCVQ456kp/o6CtY=";
    }
    |> crop16x9;
}
