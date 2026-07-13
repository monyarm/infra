{
  image,
  fetchPixiv,
  ...
}:
with image;
{
  ghostCereal =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/01/15/21/02/01/115198453_p0.jpg";
      sha256 = "sha256-yT2KrjIRanBB6/1+EfRH9/+wD01ThzY8XtqoClsukzA=";
    }
    |> crop16x9;
}
