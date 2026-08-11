{
  pkgs,
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
    pkgs.runCommand "${getName src}-minified.css"
      {
        nativeBuildInputs = [ pkgs.lightningcss ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        lightningcss --minify "${src}" > tmp.out || rm -f tmp.out
        ${guardSizeTail "tmp.out" src}
      '';
  extensions = [ "css" ];
}
