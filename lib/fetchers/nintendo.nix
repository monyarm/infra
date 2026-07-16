{
  pkgs,
  getFileNameFromUrl,
  importSopsString,
  dirs,
  userAgent,
  ...
}:
{
  fetchMyNintendo =
    {
      url,
      sha256,
      name ? null,
      cookie ? (importSopsString "${dirs.secrets}/mynintendo.cookie"),
    }:
    let
      outName =
        if name == null then
          (builtins.replaceStrings [ "/" ":" ] [ "-" "-" ] (getFileNameFromUrl url))
        else
          name;
    in
    pkgs.runCommand outName
      {
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        allowSubstitutes = false;
        outputHash = sha256;
        buildInputs = [ pkgs.curl ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        ;
                set -e
                mkdir $out

                FINAL_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' \
                  --user-agent "${userAgent}" \
                  --cookie "${cookie}" \
                  "${url}")

                CLEAN_NAME=$(basename "''${FINAL_URL%%\?*}")

                sleep 2

                curl -A "${userAgent}" --cookie "${cookie}" -o "$out/$CLEAN_NAME" -L "''${FINAL_URL}"
      '';
}
