{ pkgs, ... }:
{
  programs.mcp = {
    enable = true;
    servers = {
      codegraph = {
        command = "${pkgs.codegraph}/bin/codegraph";
        args = [
          "serve"
          "--mcp"
        ];
      };

      # microsoft's MarkItDown -- docx/pdf/pptx/xlsx/html to markdown before Claude reads it
      markitdown = {
        command = "${pkgs.markitdown-mcp}/bin/markitdown-mcp";
      };

      # wraps codegraph + markitdown, compresses their tool surfaces/results
      compressed-tools = {
        command = "${pkgs.mcp-compressor}/bin/mcp-compressor";
        args = [
          "-c"
          "medium"
          "--"
          "${pkgs.codegraph}/bin/codegraph"
          "serve"
          "--mcp"
        ];
      };
    };
  };
}
