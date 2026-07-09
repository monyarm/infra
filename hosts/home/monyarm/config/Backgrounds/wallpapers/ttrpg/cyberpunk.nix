{ image, fetchPixiv, ... }:
with image;
{
  rebecca =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2022/09/18/18/05/21/101313648_p0.jpg";
      sha256 = "sha256-ZrzegXN8PJW49JbuvYg5WyiCalQuy395oqmGig8Fj7Q=";
    }
    |> crop16x9West;
}
