{ pkgs, guardSize, getName, ... }:
# Metadata lives in ASF header objects (Content Description, Extended
# Content Description, Metadata/Metadata Library) separate from the encoded
# audio frames -- -map_metadata -1 with a stream copy drops all of them
# without touching the audio at all. Verified losslessly against a real
# ffmpeg-generated WMA: PCM-identical decode before/after stripping. Same
# technique as wav.nix's stripMetadata; falls back to the original file if
# ffmpeg can't handle it (mirrors the wav/png failsafe pattern).
src:
guardSize (pkgs.runCommand "${getName src}-stripped.wma"
  {
    nativeBuildInputs = [ pkgs.ffmpeg-headless ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    ffmpeg -y -i "${src}" -map_metadata -1 -fflags +bitexact -c copy "$out" \
      || cp "${src}" "$out"
  ''
) src
