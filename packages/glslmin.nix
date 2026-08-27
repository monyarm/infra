# The glslmin runner (lib/optimize/js/npm/glsl-optimize) packaged as a
# self-contained executable: npm dependencies are installed at BUILD time
# (offline, against the fetchNpmDeps cache FOD) so consumers never need
# node/npm themselves. Exposes bin/glslmin, usable directly:
#
#   glslmin <file>   (prints the minified GLSL to stdout)
#
# A proper package rather than a handler-local let so the dynamic-optimize
# inner sandbox can overlay it as a prebuilt store path like any other tool
# -- see dynamic.nix's handlerTools.
{
  stdenv,
  nodejs,
  fetchNpmDeps,
  ...
}:

let
  glslOptimizeDir = ../lib/optimize/js/npm/glsl-optimize;

  nodeModules = fetchNpmDeps {
    name = "glsl-optimize-npm-deps";
    # fetchNpmDeps's own build script only ever reads package-lock.json
    # (never package.json), and outputHash is declared, not derived from
    # src -- verified via a real build that this single-file src produces
    # the exact same output path as pointing at the whole containing dir.
    src = "${glslOptimizeDir}/package-lock.json";
    hash = "sha256-PfDgD+5sAQtkBiJV2pWjRUiHvY7f+EZ5n4A399Cb/rc=";
  };
in
stdenv.mkDerivation {
  name = "glslmin-0-unstable";
  src = glslOptimizeDir;

  nativeBuildInputs = [ nodejs ];

  configurePhase = ''
    runHook preConfigure
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    # npm writes into its cache dir even offline, so it needs to be writable;
    # the fetched cache is a read-only store path.
    cp -r ${nodeModules} "$TMPDIR/npm-cache"
    chmod -R u+w "$TMPDIR/npm-cache"
    export npm_config_cache="$TMPDIR/npm-cache"
    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/glslmin" "$out/bin"
    cp glslmin.js package.json package-lock.json "$out/share/glslmin"/
    (
      cd "$out/share/glslmin"
      # node_modules resolves relative to the script's own directory (see
      # the wrapper below), which is why ci runs here, not in $TMPDIR.
      npm ci --offline --no-audit --no-fund
    )
    # Absolute node path baked in: the wrapper works from any cwd and any
    # PATH, including the inner optimize sandbox's stripped one. The middle
    # line is deliberately single-quoted: $0/$dir must resolve at RUNTIME.
    {
      echo "#!${stdenv.shell}"
      echo 'dir="$(dirname "$(readlink -f "$0")")/../share/glslmin"'
      echo "exec ${nodejs}/bin/node \"\$dir/glslmin.js\" \"\$@\""
    } > "$out/bin/glslmin"
    chmod +x "$out/bin/glslmin"
    runHook postInstall
  '';

  meta = {
    description = "GLSL whitespace/comment stripper used by the optimize pipeline";
  };
}
