{
  pkgs,
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
    pkgs.runCommand "${getName src}-stripped"
      {
        nativeBuildInputs = [ pkgs.gawk ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        gawk '
          BEGIN { IGNORECASE = 1 }
          /^[[:space:]]*(rem([[:space:]]|$)|::)/ { next }
          /^[[:space:]]*$/ { next }
          { print }
        ' "${src}" > tmp.out || rm -f tmp.out
        ${guardSizeTail "tmp.out" src}
      '';
  extensions = [
    "bat"
    "cmd"
  ];
}
