{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
let
  # Re-encode to FLAC (lossless), keep the .wav name -- GZDoom sniffs
  # content by magic bytes, not extension. Raw `derivation`, not
  # pkgs.runCommand: same reasoning as the main handlers -- the inner
  # sandbox overlays tools as store-path strings and must never construct
  # real nixpkgs packages (stdenv boot).
  toFlacKeepName =
    src:
    derivation {
      name = "${getName src}.flac";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.flac}/bin
          # Some real Doom-mod "wav" lumps are raw/mislabeled and aren't
          # actually a WAVE container -- flac hard-refuses those (it needs
          # --endian/--sign/--channels/--bps/--sample-rate for raw input,
          # which we don't have). Fall back to the original file unchanged,
          # same as png.nix's pattern.
          flac --best --silent -f -o tmp.flac "${src}" || rm -f tmp.flac
          ${guardSizeTail "tmp.flac" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
in
{
  handler = toFlacKeepName;
}
