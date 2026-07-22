{
  fetchHtmlThenCurl,
  ...
}:
{
  fetchGameBanana =
    {
      fileId,
      sha256,
      name ? "gamebanana-${toString fileId}",
    }:
    fetchHtmlThenCurl { #Using this fetcher to allow for extracting if it's an archive
      inherit name;
      outputHash = sha256;
      outputHashMode = "recursive";
      extract = true;
      # /mmdl/<fileId> is GameBanana's "Download with Mod Manager" link; it's a
      # plain 302 redirect straight to the CDN file, no page-scraping needed.
      resolve = ''
        RESOLVED_URL="https://gamebanana.com/mmdl/${toString fileId}"
      '';
    };
}
