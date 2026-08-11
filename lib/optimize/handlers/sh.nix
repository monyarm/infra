{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# Shell scripts: drop full "#" comment lines and blank lines. A line-1
# shebang starts with "#" too but must survive -- stripping it would break
# execution -- so it's special-cased ahead of the generic comment rule.
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
          NR == 1 && /^#!/ { print; next }
          /^[[:space:]]*#/ { next }
          /^[[:space:]]*$/ { next }
          { print }
        ' "${src}" > tmp.out || rm -f tmp.out
        ${guardSizeTail "tmp.out" src}
      '';
  extensions = [
    "sh"
    "bash"
    "zsh"
  ];
}
