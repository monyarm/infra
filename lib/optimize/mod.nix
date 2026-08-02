{ pkgs, guardSize, getName, ... }:
# Zeroes only the cosmetic title/sample-name text in a ProTracker-family
# .mod (modstrip.py) -- pattern/sample audio data is never touched.
# Verified GZDoom never reads that text for anything: ZMusic's actual
# libxmp playback backend (music_libxmp.cpp) only calls
# xmp_test_module_from_callbacks/xmp_load_module_from_callbacks/
# xmp_play_buffer for pure audio decode, never xmp_get_module_info -- no
# HUD/display hookup exists. modstrip.py itself checks the format tag and
# leaves anything that isn't a recognized ProTracker-family module (i.e. a
# .mod-extensioned file that's actually something else) untouched.
src:
guardSize (pkgs.runCommand "${getName src}-stripped.mod"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    python3 ${./modstrip.py} "${src}" "$out"
  ''
) src
