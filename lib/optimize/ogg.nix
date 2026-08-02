{ pkgs, guardSize, getName, ... }:
# Strips Vorbis-comment metadata via stream copy -- genuinely lossless, no
# re-encode (verified: decoded PCM identical before/after on a real tagged
# file, same approach as wav.nix's stripMetadata). -fflags +bitexact also
# suppresses ffmpeg's own auto-added "encoder=Lavf..." tag, which
# -map_metadata -1 alone leaves behind.
src:
guardSize (pkgs.runCommand "${getName src}-stripped.ogg"
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
