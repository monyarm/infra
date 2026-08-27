{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# Windows batch scripts: drop full-line "rem"/"::" comments (case-
# insensitive) and blank lines. Batch has no inline-comment syntax, so
# unlike sh.nix there's no mid-line case to worry about.
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
          export PATH=${pkgs.coreutils}/bin:${pkgs.gawk}/bin
          gawk '
            BEGIN { IGNORECASE = 1 }
            /^[[:space:]]*(rem([[:space:]]|$)|::)/ { next }
            /^[[:space:]]*$/ { next }
            { print }
          ' "${src}" > tmp.out || rm -f tmp.out
          ${guardSizeTail "tmp.out" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [
    "bat"
    "cmd"
  ];
}
