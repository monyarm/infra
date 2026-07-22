{
  pkgs,
  getFileNameFromUrl,
  userAgent,
  lib,
  fetchHtmlThenCurl,
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
    fetchHtmlThenCurl {
      name = outName;
      outputHash = sha256;
      outputHashMode = "recursive";
      nativeBuildInputs = [ pkgs.curl ];
      useSecrets = true;
      extraAttrs = {
        preferLocalBuild = true;
        impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [ "NINTENDO_COOKIE" ];
      };
      resolve = ''
        FINAL_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' \
          --user-agent "${userAgent}" \
          --cookie "$NINTENDO_COOKIE" \
          "${url}")

        sleep 2
        RESOLVED_URL="$FINAL_URL"
      '';
      curlOpts = ''-A "${userAgent}" --cookie "$NINTENDO_COOKIE"'';
    };
}
