{ pkgs, ... }:
{
  dateEverything = pkgs.fetchurl {
    url = "https://dateeverything.com/hs-fs/hubfs/Date%20Everything%20Key%20Art.png";
    sha256 = "sha256-jAlIZNcNPyPtUYCeLot5kgyCH+iX26LdpK3zZytj47k=";
  };
}
