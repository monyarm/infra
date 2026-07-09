{ image, fetchPixiv, ... }:
with image;
{
  melina =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/09/19/21/54/02/122584562_p0.jpg";
      sha256 = "sha256-BPzMhV0w3FavDsiZ5bKQan0X/dPpOfM6MtHbzEjh6Kg=";
    }
    |> crop16x9West;
}
