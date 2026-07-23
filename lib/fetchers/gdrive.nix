{
  pkgs,
  fetchToolOutput,
  extractArchiveSnippet,
  ...
}:
{
  fetchGDrive =
    {
      fileId,
      sha256,
      name ? fileId,
      # Set this when the gdrive download is an archive (zip/rar/etc) that
      # should be unpacked, rather than a single file (e.g. a .pk3) to keep
      # intact as-is.
      extract ? false,
    }:
    fetchToolOutput {
      inherit name;
      outputHash = sha256;
      outputHashMode = if extract then "recursive" else "flat";
      nativeBuildInputs = [
        pkgs.gdown
        pkgs.cacert
      ];
      extraAttrs = {
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      script =
        if extract then
          ''
            export HOME=$TMPDIR
            DOWNLOADED_FILE="$TMPDIR/downloaded"
            gdown "${fileId}" -O "$DOWNLOADED_FILE"
            mkdir -p "$out"
            ${extractArchiveSnippet {
              file = "$DOWNLOADED_FILE";
              outDir = "$out";
            }}
          ''
        else
          ''
            export HOME=$TMPDIR
            gdown "${fileId}" -O "$out"
          '';
    };
}
