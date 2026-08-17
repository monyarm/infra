{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
let
  # Re-encode to FLAC (lossless), keep the .wav name -- GZDoom sniffs
  # content by magic bytes, not extension.
  toFlacKeepName =
    src:
    pkgs.runCommand "${getName src}.flac"
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
        flac --best --silent -f -o tmp.flac "${src}" || rm -f tmp.flac
        ${guardSizeTail "tmp.flac" src}
      '';
in
{
  handler = toFlacKeepName;
}
