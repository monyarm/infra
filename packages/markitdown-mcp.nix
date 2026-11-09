{
  lib,
  python3Packages,
  fetchPypi,
  ...
}:

let
  # tests off: their check inputs (markitdown: every optional dep; mcp:
  # logfire, opentelemetry, ...) are all evaluated otherwise -- eval cost only
  noCheck = p: p.overridePythonAttrs { doCheck = false; };
in
python3Packages.buildPythonApplication rec {
  pname = "markitdown-mcp";
  version = "0.0.1a4";
  pyproject = true;

  src = fetchPypi {
    pname = "markitdown_mcp";
    inherit version;
    hash = "sha256-MJyU3IgzEeaQnYSTgqbHvEAt+yaS2rRIwTbGhkxr9J4=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = [
    (noCheck python3Packages.mcp)
    (noCheck python3Packages.markitdown)
  ];

  pythonRelaxDeps = true;

  meta = {
    description = "MCP server for Microsoft's MarkItDown (docx/pdf/pptx/xlsx/html to markdown)";
    homepage = "https://github.com/microsoft/markitdown";
    license = lib.licenses.mit;
    mainProgram = "markitdown-mcp";
    platforms = lib.platforms.unix;
  };
}
