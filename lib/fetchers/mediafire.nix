{
  pkgs,
  userAgent,
  fetchHtmlThenCurl,
  getFileNameFromUrl,
  ...
}:
{
  fetchMediafire =
    {
      url,
      sha256,
      # Mediafire urls look like .../file/<id>/<filename>/file; prefer the
      # actual filename segment over the trailing literal "file".
      name ?
        let
          m = builtins.match ".*/file/[^/]+/([^/]+)/file/?" url;
        in
        if m != null then builtins.head m else getFileNameFromUrl url,
    }:
    fetchHtmlThenCurl {
      inherit name;
      outputHash = sha256;
      outputHashMode = "flat";
      nativeBuildInputs = [
        pkgs.curl
        pkgs.gnugrep
      ];
      resolve = ''
        page=$(curl -sL --user-agent "${userAgent}" "${url}")
        # The CDN download link is easier to find as a plain URL pattern than
        # by parsing the surrounding <a> tag: mediafire has changed the
        # attribute order/markup around id="downloadButton" over time.
        resolved=$(printf '%s' "$page" | grep -oE 'https://download[a-zA-Z0-9]*\.mediafire\.com/[^"'"'"'<> ]+' | head -1)

        if [ -z "$resolved" ]; then
          # Some mediafire links serve the file directly instead of an HTML
          # wrapper page (no downloadButton to scrape); fall back to the
          # original url in that case.
          RESOLVED_URL="${url}"
        else
          RESOLVED_URL="$resolved"
        fi
      '';
      curlOpts = ''--user-agent "${userAgent}"'';
    };
}
