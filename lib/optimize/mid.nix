{ pkgs, guardSize, getName, ... }:
# Strips display-only MIDI meta-events (track name, copyright, lyrics,
# markers, ...) via a lossless midicsv/csvmidi round-trip -- verified on a
# real file (action.pk3's CHOPPA2.mid): reconverting the stripped .mid back
# to CSV produces byte-identical output, and every Note_on/off/Control/
# Program/Tempo/Time_signature/Key_signature event is left untouched.
src:
guardSize (pkgs.runCommand "${getName src}-stripped.mid"
  {
    nativeBuildInputs = [ pkgs.midicsv ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    midicsv "${src}" tmp.csv
    grep -vE ', (Title_t|Copyright_t|Text_t|Lyric_t|Marker_t|Cue_point_t|Instrument_name_t|Sequencer_specific_t|Device_name_t|Program_name_t),' tmp.csv > tmp-stripped.csv
    csvmidi tmp-stripped.csv "$out"
  ''
) src
