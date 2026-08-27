{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# glsl-man reprints the AST with whitespace/comments stripped. Falls back
# to the original on parse failure. pkgs.glslmin is packages/glslmin.nix --
# runner + node_modules bundled into one bin/glslmin executable -- overlaid
# as a prebuilt store path in the inner sandbox; see that file's header.
{
  handler =
    src:
    derivation {
      name = "${getName src}-glslmin";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.glslmin}/bin
          { glslmin "${src}" || cat "${src}"; } > tmp.glsl
          ${guardSizeTail "tmp.glsl" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [
    "fp"
    "vp"
    "frag"
    "gl"
    "ps"
    "pso"
  ];
}
