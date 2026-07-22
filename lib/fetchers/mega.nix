{
  pkgs,
  fetchToolOutput,
  extractArchiveSnippet,
  getFileNameFromUrl,
  ...
}:
{
  fetchMega =
    {
      url,
      sha256,
      name ? getFileNameFromUrl url,
    }:
    fetchToolOutput {
      inherit name;
      outputHash = sha256;
      outputHashMode = "recursive";
      nativeBuildInputs = [
        pkgs.megatools
        pkgs.cacert
      ];
      extraAttrs = {
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      script = ''
        mkdir -p "$TMPDIR/download"
        megadl --no-progress --path "$TMPDIR/download" "${url}"

        DOWNLOADED_FILE=$(find "$TMPDIR/download" -maxdepth 1 -type f | head -1)
        if [ -z "$DOWNLOADED_FILE" ]; then
          echo "Error: megadl did not produce a file." >&2
          exit 1
        fi

        mkdir -p "$out"
        ${extractArchiveSnippet {
          file = "$DOWNLOADED_FILE";
          outDir = "$out";
        }}
      '';
    };
}
