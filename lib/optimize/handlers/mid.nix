{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# Strips display-only MIDI meta-events (name, copyright, lyrics, markers)
# via a lossless midicsv/csvmidi round-trip.
src:
derivation {
  name = "${getName src}-stripped.mid";
  inherit system;
  builder = "${pkgs.bash}/bin/bash";
  args = [
    "-c"
    ''
      export PATH=${pkgs.coreutils}/bin:${pkgs.midicsv}/bin:${pkgs.gnugrep}/bin
      (
        set -e
        midicsv "${src}" tmp.csv
        grep -vE ', (Title_t|Copyright_t|Text_t|Lyric_t|Marker_t|Cue_point_t|Instrument_name_t|Sequencer_specific_t|Device_name_t|Program_name_t),' tmp.csv > tmp-stripped.csv
        csvmidi tmp-stripped.csv tmp.mid
      ) || rm -f tmp.mid
      ${guardSizeTail "tmp.mid" src}
    ''
  ];
  allowSubstitutes = false;
  __contentAddressed = true;
  outputHashAlgo = "sha256";
  outputHashMode = "flat";
}
