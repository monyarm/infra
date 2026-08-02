{ pkgs, guardSize, getName, ... }:
let
  # Drop metadata/tag chunks only, keep it a real WAV -- genuinely lossless,
  # no re-encoding, always safe. -fflags +bitexact also suppresses ffmpeg's
  # own auto-added "encoder=Lavf..." tag, which -map_metadata -1 alone
  # leaves behind.
  stripMetadata =
    src:
    guardSize (pkgs.runCommand "${getName src}-stripped.wav"
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
    ) src;

  # Re-encode to FLAC (audio is still bit-identical, so this is lossless too)
  # but keep the original .wav name -- verified against GZDoom's actual
  # source (s_sound.cpp/filesystem.cpp): sound decoding sniffs content by
  # magic bytes, never by extension, so a FLAC-content file named .wav loads
  # fine as long as the filename SNDINFO/DECORATE reference doesn't change,
  # which the shared `rename` step in default.nix guarantees. Kept as the
  # "prime" (opt-in, not the plain-optimize default) handler, since it leans
  # on every consumer's content-sniffing behavior holding, not just GZDoom's.
  toFlacKeepName =
    src:
    guardSize (pkgs.runCommand "${getName src}.flac"
      {
        nativeBuildInputs = [ pkgs.flac ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        # Some real Doom-mod "wav" lumps are raw/mislabeled and aren't
        # actually a WAVE container -- flac hard-refuses those (it needs
        # --endian/--sign/--channels/--bps/--sample-rate for raw input,
        # which we don't have). Fall back to the original file unchanged,
        # same as png.nix's pattern.
        flac --best --silent -f -o tmp.flac "${src}" || true
        mv tmp.flac "$out" || true
        [ -e "$out" ] || cp "${src}" "$out"
      ''
    ) src;
in
{
  normal = stripMetadata;
  prime = toFlacKeepName;
}
