{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# metaflac strips metadata blocks only, no re-encode. --remove-all keeps STREAMINFO.
src:
derivation {
  name = "${getName src}-stripped.flac";
  inherit system;
  builder = "${pkgs.bash}/bin/bash";
  args = [
    "-c"
    ''
      export PATH=${pkgs.coreutils}/bin:${pkgs.flac}/bin
      cp "${src}" tmp.flac
      chmod +w tmp.flac
      metaflac --remove-all --dont-use-padding tmp.flac || rm -f tmp.flac
      ${guardSizeTail "tmp.flac" src}
    ''
  ];
  allowSubstitutes = false;
  __contentAddressed = true;
  outputHashAlgo = "sha256";
  outputHashMode = "flat";
}
