{
  pkgs,
  fetchToolOutput,
  ...
}:
{
  fetchGDrive =
    {
      fileId,
      sha256,
      name ? fileId,
    }:
    fetchToolOutput {
      inherit name;
      outputHash = sha256;
      outputHashMode = "flat";
      nativeBuildInputs = [
        pkgs.gdown
        pkgs.cacert
      ];
      extraAttrs = {
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      script = ''
        export HOME=$TMPDIR
        gdown --id "${fileId}" -O "$out"
      '';
    };
}
