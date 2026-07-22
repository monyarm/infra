{
  pkgs,
  getFileNameFromUrl,
  userAgent,
  lib,
  ...
}:
{
  fetchMyNintendo =
    {
      url,
      sha256,
      name ? null,
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
        preferLocalBuild = true;
        outputHash = sha256;
        buildInputs = [ pkgs.curl ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [ "NINTENDO_COOKIE" ];
      }
      ''
        set -e
        mkdir $out
        source /secrets

        FINAL_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' \
          --user-agent "${userAgent}" \
          --cookie "$NINTENDO_COOKIE" \
          "${url}")

        CLEAN_NAME=$(basename "''${FINAL_URL%%\?*}")

        sleep 2

        curl -A "${userAgent}" --cookie "$NINTENDO_COOKIE" -o "$out/$CLEAN_NAME" -L "''${FINAL_URL}"
      '';
}
