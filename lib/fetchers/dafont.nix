{ pkgs, ... }:
{
  fetchDafont =
    fontName: sha256:
    pkgs.fetchzip {
      url = "https://dl.dafont.com/dl/?f=${fontName}#${fontName}.zip";
      name = fontName;
      stripRoot = false;
      inherit sha256;
    };
}
