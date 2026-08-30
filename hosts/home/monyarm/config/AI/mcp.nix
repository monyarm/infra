{ pkgs, ... }:
{
  programs.mcp = {
    enable = true;
    servers = {
      # microsoft's MarkItDown -- docx/pdf/pptx/xlsx/html to markdown before Claude reads it
      markitdown = {
        command = "${pkgs.markitdown-mcp}/bin/markitdown-mcp";
        timeout = 60000;
      };

      # Compresses local tool metadata; results normally pass through unchanged.
      # --toonify converts structured JSON results to token-efficient TOON.
      compressed-codegraph = {
        command = "${pkgs.mcp-compressor}/bin/mcp-compressor";
        args = [
          "-c"
          "medium"
          "--toonify"
          "--"
          "${pkgs.codegraph}/bin/codegraph"
          "serve"
          "--mcp"
        ];
      };

      # Remote URLs must be passed directly. The pinned compressor does not
      # support URL backends in its MCP config JSON parser.
      compressed-context7 = {
        command = "${pkgs.mcp-compressor}/bin/mcp-compressor";
        args = [
          "-c"
          "medium"
          "--toonify"
          "--"
          "https://mcp.context7.com/mcp"
        ];
      };
      compressed-gh-grep = {
        command = "${pkgs.mcp-compressor}/bin/mcp-compressor";
        args = [
          "-c"
          "medium"
          "--toonify"
          "--"
          "https://mcp.grep.app"
        ];
      };
    };
  };
}
