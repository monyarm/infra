{
  pkgs,
  getFileNameFromUrl,
  userAgent,
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
