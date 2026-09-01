{
  lib,
  rustPlatform,
  fetchGitTree,
  sources,
  ...
}:

let
  compressorSource = sources.tools.mcp-compressor;
  src = fetchGitTree (
    removeAttrs compressorSource [
      "cargoLock"
      "cargoOutputHashes"
    ]
  );
  version = compressorSource.tag or "0-unstable-${compressorSource.date}";
in
rustPlatform.buildRustPackage {
  pname = "mcp-compressor";
  inherit version src;

  cargoLock = {
    lockFile = builtins.toFile "mcp-compressor-Cargo.lock" compressorSource.cargoLock;
    outputHashes = compressorSource.cargoOutputHashes or { };
  };
  # workspace also has python/node binding crates (pyo3/napi) -- only need the CLI
  buildAndTestSubdir = "crates/mcp-compressor";
  # integration tests spawn external fixtures not available in the sandbox
  doCheck = false;

  meta = {
    description = "MCP server wrapper that compresses tool descriptions/results before they reach the model";
    homepage = "https://atlassian-labs.github.io/mcp-compressor/";
    license = lib.licenses.asl20;
    mainProgram = "mcp-compressor";
    platforms = lib.platforms.unix;
  };
}
