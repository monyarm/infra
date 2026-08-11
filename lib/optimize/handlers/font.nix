{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# fonttools subset, --glyphs='*' keeps every glyph -- strip hints, don't
# subset. Tested vs DejaVuSans: glyf shrinks, hmtx identical, nothing lost.
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
          --output-file=tmp.out || rm -f tmp.out
        ${guardSizeTail "tmp.out" src}
      '';
  extensions = [
    "ttf"
    "otf"
  ];
}
