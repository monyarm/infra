{ pkgs, guardSize, getName, ... }:
# Ports gameoptimizer's glslmin.js (github.com/monyarm/gameoptimizer,
# src/deps/glslmin.js) unmodified: a real GLSL parser (npm's glsl-man,
# pinned via ./npm/package-lock.json) reprints the AST with all
# whitespace/comments stripped -- verified against a real fetched shader
# (UJJD.pk3's Shaders/rotate.fp) to produce a semantically-equivalent
# minified program. On any parse failure (e.g. a non-GLSL file that
# happens to share one of these extensions) node exits non-zero and the
# original file is copied through untouched -- verified against random
# binary data.
let
  nodeModules = pkgs.fetchNpmDeps {
    name = "glsl-optimize-npm-deps";
    src = ./npm;
    hash = "sha256-PfDgD+5sAQtkBiJV2pWjRUiHvY7f+EZ5n4A399Cb/rc=";
  };
in
src:
guardSize (pkgs.runCommand "${getName src}-glslmin"
  {
    nativeBuildInputs = [ pkgs.nodejs ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    cp ${./npm/package.json} ./package.json
    cp ${./npm/package-lock.json} ./package-lock.json
    cp ${./glslmin.js} ./glslmin.js
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
    { node ./glslmin.js "${src}" || cat "${src}"; } > "$out"
  ''
) src
