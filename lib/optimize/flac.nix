{ pkgs, guardSize, getName, ... }:
# metaflac operates directly on FLAC metadata blocks (Vorbis comments,
# pictures, application data, seektable, padding) without touching the
# encoded audio at all -- genuinely lossless, no re-encode. --remove-all
# leaves STREAMINFO alone (required for playback).
src:
guardSize (pkgs.runCommand "${getName src}-stripped.flac"
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
    metaflac --remove-all --dont-use-padding tmp.flac
    mv tmp.flac "$out"
  ''
) src
