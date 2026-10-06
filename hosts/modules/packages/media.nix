# Media creation/editing. Home-manager only -- these are desktop applications.
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    audacity
    dejavu_fonts
    ffmpeg
    gimp
    imagemagickBig
    inkscape
    pdf-cli
    pdfarranger
    poppler-utils
    sox
    vips
  ];
}
