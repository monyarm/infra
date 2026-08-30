{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  sources,
  ...
}:
stdenv.mkDerivation {
  pname = "codegraph";
  inherit (sources.tools.codegraph) version;

  src = fetchurl {
    inherit (sources.tools.codegraph) url hash;
  };

  # bundled node binary needs libstdc++ (checked with ldd), rest is glibc
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  sourceRoot = "package";
  dontConfigure = true;
  dontBuild = true;

  # `bin/codegraph` is a POSIX shell wrapper (resolves symlinks, then execs the bundled
  # `node` against the bundled `lib/` tree) -- install the whole extracted tree and expose
  # that wrapper directly; no need to reproduce the main npm package's install-time shim.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec/codegraph
    cp -r bin lib node package.json $out/libexec/codegraph/
    mkdir -p $out/bin
    ln -s $out/libexec/codegraph/bin/codegraph $out/bin/codegraph
    runHook postInstall
  '';

  meta = {
    description = "Pre-indexed code knowledge graph MCP server";
    homepage = "https://github.com/colbymchenry/codegraph";
    license = lib.licenses.mit;
    mainProgram = "codegraph";
    platforms = [ "x86_64-linux" ]; # only linux-x64's binary is pinned/hashed so far
  };
}
