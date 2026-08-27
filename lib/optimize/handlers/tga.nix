{
  pkgs,
  system,
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
    derivation {
      name = "${getName src}-optimized.tga";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.imagemagick}/bin
          magick convert "${src}" -compress RLE tmp.tga || rm -f tmp.tga
          ${guardSizeTail "tmp.tga" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
}
