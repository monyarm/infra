{ pkgs, ... }:
{
  untilDawn = pkgs.fetchurl {
    url = "https://sonyinteractive.com/tachyon/2025/02/Games_Until-Dawn.jpg";
    sha256 = "sha256-u2qluVqC50E8Cm/RJd1eeZquru1S4wBjW863NxQPqao=";
  };
}
