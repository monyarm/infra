{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
let
  guardTmpJpg = guardSizeTail "tmp.jpg";

  jpegoptim =
    src:
    derivation {
      name = "${getName src}-jpegoptim.jpg";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.jpegoptim}/bin:${pkgs.mozjpeg}/bin
          cp "${src}" tmp.jpg
          jpegoptim --strip-all --all-normal tmp.jpg || rm -f tmp.jpg
          ${guardTmpJpg src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };

  mozjpeg =
    src:
    derivation {
      name = "${getName src}-mozjpeg.jpg";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.jpegoptim}/bin:${pkgs.mozjpeg}/bin
          cjpeg -quality 85 -optimize "${src}" > tmp.jpg || rm -f tmp.jpg
          ${guardTmpJpg src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
in
{
  normal = src: src |> jpegoptim;
  prime = src: src |> mozjpeg;
  extensions = [ "jpg" ];
}
