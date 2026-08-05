{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# metaflac strips metadata blocks only, no re-encode. --remove-all keeps STREAMINFO.
src:
pkgs.runCommand "${getName src}-stripped.flac"
  {
    nativeBuildInputs = [ pkgs.flac ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    cp "${src}" tmp.flac
    chmod +w tmp.flac
    metaflac --remove-all --dont-use-padding tmp.flac || rm -f tmp.flac
    ${guardSizeTail "tmp.flac" src}
  ''
