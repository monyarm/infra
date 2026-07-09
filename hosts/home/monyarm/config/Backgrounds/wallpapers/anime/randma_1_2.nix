{ image, fetchPixiv, ... }:
with image;
{
  ranmalloween2024 =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/10/23/14/09/20/123598376_p0.png";
      sha256 = "sha256-GUyxZ8RbIa9jBJ3eSRB4/X97K/2SMJ4/gWI9bgdMnuE=";
    }
    |> crop16x9;
}
