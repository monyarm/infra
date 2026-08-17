{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# fonttools subset, --glyphs='*' keeps every glyph -- strip hints, don't
# subset. Tested vs DejaVuSans: glyf shrinks, hmtx identical, nothing lost.
# FFTM: FontForge timestamp table, nonstandard, no subset_glyphs impl --
# drop explicit, else fonttools warns and drops it anyway.
let
  fonttools = pkgs.python3.withPackages (ps: [ ps.fonttools ]);
in
{
  handler =
    src:
    pkgs.runCommand "${getName src}-stripped"
      {
        nativeBuildInputs = [ fonttools ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        fonttools subset "${src}" \
          --glyphs='*' \
          --layout-features='*' \
          --name-IDs='*' \
          --notdef-outline \
          --recommended-glyphs \
          --no-hinting \
          --drop-tables+=FFTM \
          --output-file=tmp.out || rm -f tmp.out
        ${guardSizeTail "tmp.out" src}
      '';
  extensions = [
    "ttf"
    "otf"
  ];
}
