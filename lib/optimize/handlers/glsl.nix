{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# glsl-man reprints the AST with whitespace/comments stripped. Falls back
# to the original on parse failure.
let
  nodeModules = pkgs.fetchNpmDeps {
    name = "glsl-optimize-npm-deps";
    # fetchNpmDeps's own build script only ever reads package-lock.json
    # (never package.json), and outputHash is declared, not derived from
    # src -- verified via a real build that this single-file src produces
    # the exact same output path as pointing at the whole containing dir.
    src = ../js/npm/glsl-optimize/package-lock.json;
    hash = "sha256-PfDgD+5sAQtkBiJV2pWjRUiHvY7f+EZ5n4A399Cb/rc=";
  };
  handler =
    src:
    pkgs.runCommand "${getName src}-glslmin"
      {
        nativeBuildInputs = [ pkgs.nodejs ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp ${../js/npm/glsl-optimize/package.json} ./package.json
        cp ${../js/npm/glsl-optimize/package-lock.json} ./package-lock.json
        cp ${../js/npm/glsl-optimize/glslmin.js} ./glslmin.js
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        # npm writes into its cache dir even offline, so it needs to be writable
        cp -r ${nodeModules} "$TMPDIR/npm-cache"
        chmod -R u+w "$TMPDIR/npm-cache"
        export npm_config_cache="$TMPDIR/npm-cache"
        npm ci --offline --no-audit --no-fund >/dev/null
        # glslmin.js must run from here, not its nix store path -- node's
        # require() resolves node_modules relative to the running script's own
        # directory, not $PWD.
        { node ./glslmin.js "${src}" || cat "${src}"; } > tmp.glsl
        ${guardSizeTail "tmp.glsl" src}
      '';
in
{
  inherit handler;
  extensions = [
    "fp"
    "vp"
    "frag"
    "gl"
    "ps"
    "pso"
  ];
}
