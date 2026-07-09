{ pkgs, image, ... }:
with image;
{
  komiNajimiBathouse =
    pkgs.fetchurl {
      name = "komiNajimiBathouse.jpg";
      url = "https://pbs.twimg.com/media/FmXT_XUaMAAW3KL?format=jpg&name=4096x4096";
      sha256 = "sha256-vkuw+j/WI36cYzV6nnbRXLGYc03+fGrTS3v81txK2wU=";
    }
    |> crop16x9;
}
