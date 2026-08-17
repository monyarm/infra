{
  lib,
  rustPlatform,
  fetchGitTree,
  sources,
  ...
}:

let
  src = fetchGitTree sources.tools.mcp-compressor;
  version = sources.tools.mcp-compressor.tag or "0-unstable-${sources.tools.mcp-compressor.date}";
in
rustPlatform.buildRustPackage {
  pname = "mcp-compressor";
  inherit version src;

  cargoLock.lockFile = "${src}/Cargo.lock";
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
