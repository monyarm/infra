{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# fonttools subset, --glyphs='*' keeps every glyph -- strip hints, don't
# subset. Tested vs DejaVuSans: glyf shrinks, hmtx identical, nothing lost.
# FFTM: FontForge timestamp table, nonstandard, no subset_glyphs impl --
# drop explicit, else fonttools warns and drops it anyway. pkgs.fonttools is
# packages/fonttools.nix (python3 + fonttools), overlaid as a prebuilt store
# path in the inner sandbox -- see packages/fonttools.nix's header.
{
  handler =
    src:
    derivation {
      name = "${getName src}-stripped";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.fonttools}/bin
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
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [
    "ttf"
    "otf"
  ];
}
