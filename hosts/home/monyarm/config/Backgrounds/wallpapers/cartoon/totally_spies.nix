{
  pkgs,
  image,
  ...
}:
with image;
{
  spiesCasual01 =
    pkgs.fetchurl {
      name = "spiesCasual01.jpg";
      url = "https://pbs.twimg.com/media/ER3ymdNWkAIBlrr?format=jpg&name=large";
      sha256 = "sha256-9RqEw1QqPZ+GnmAMqmR99UOmn5TYTZr9ESBzu/2EMlE=";
    }
    |> grow16x9;
}
