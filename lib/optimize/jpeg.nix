{ pkgs, guardSize, getName, ... }:
let
  jpegoptim =
    src:
    guardSize (pkgs.runCommand "${getName src}-jpegoptim.jpg"
      {
        buildInputs = [ pkgs.jpegoptim ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.jpg
        jpegoptim --strip-all --all-normal tmp.jpg
        mv tmp.jpg "$out"
      ''
    ) src;

  mozjpeg =
    src:
    guardSize (pkgs.runCommand "${getName src}-mozjpeg.jpg"
      {
        buildInputs = [ pkgs.mozjpeg ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cjpeg -quality 85 -optimize "${src}" > "$out"
      ''
    ) src;
in
{
  normal = src: src |> jpegoptim;
  prime = src: src |> mozjpeg;
}
