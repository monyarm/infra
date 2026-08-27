{
  pkgs,
  system,
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
    derivation {
      name = "${getName src}-stripped";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.gawk}/bin
          gawk '
            NR == 1 && /^#!/ { print; next }
            /^[[:space:]]*#/ { next }
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
    "sh"
    "bash"
    "zsh"
  ];
}
