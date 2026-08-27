{ pkgs, ... }:
let
  compressedToolsConfig = pkgs.writeText "compressed-tools-mcp.json" (
    builtins.toJSON {
      mcpServers = {
        codegraph = {
          command = "${pkgs.codegraph}/bin/codegraph";
          args = [
            "serve"
            "--mcp"
          ];
        };
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
        gh_grep = {
          url = "https://mcp.grep.app";
        };
      };
    }
  );
in
{
  programs.mcp = {
    enable = true;
    servers = {
      # microsoft's MarkItDown -- docx/pdf/pptx/xlsx/html to markdown before Claude reads it
      markitdown = {
        command = "${pkgs.markitdown-mcp}/bin/markitdown-mcp";
        timeout = 60000;
      };

      # Compresses tool metadata; results normally pass through unchanged.
      # --toonify converts structured JSON results to token-efficient TOON.
      compressed-tools = {
        command = "${pkgs.mcp-compressor}/bin/mcp-compressor";
        args = [
          "-c"
          "medium"
          "--toonify"
          "--config"
          "${compressedToolsConfig}"
        ];
      };
    };
  };
}
