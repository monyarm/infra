{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:

# Targa's own RLE mode is a lossless run-length encoding -- re-writing an
# uncompressed (or already-RLE) TGA through it never changes pixel data,
# only how many bytes it takes to say the same thing.
{
  handler =
    src:
    pkgs.runCommand "${getName src}-optimized.tga"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        magick convert "${src}" -compress RLE tmp.tga || rm -f tmp.tga
        ${guardSizeTail "tmp.tga" src}
      '';
}
