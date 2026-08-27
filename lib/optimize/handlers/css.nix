{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# lightningcss --minify: strips comments/whitespace and does safe
# semantic-preserving rewrites (0px -> 0, blue -> #00f) -- same
# "lossless in effect" bar as this repo's image handlers, not a
# byte-identical-unless-smaller transform.
{
  handler =
    src:
    derivation {
      name = "${getName src}-minified.css";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.lightningcss}/bin
          lightningcss --minify "${src}" > tmp.out || rm -f tmp.out
          ${guardSizeTail "tmp.out" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [ "css" ];
}
