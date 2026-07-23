{
  pkgs,
  fetchToolOutput,
  userAgent,
  getFileNameFromUrl,
  ...
}:
{
  fetchVideo =
    {
      url,
      sha256,
      name ? getFileNameFromUrl url,
      audio ? false,
    }:
    fetchToolOutput {
      inherit name;
      outputHash = sha256;
      outputHashMode = "flat";
      nativeBuildInputs = [ pkgs.yt-dlp ];
      extraAttrs = {
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      script = ''
        yt-dlp \
          ${if audio then "-f bestvideo+bestaudio" else "-f bestvideo"} \
          --no-playlist \
          --no-write-subs \
          --no-write-auto-subs \
          --no-write-info-json \
          --no-write-comments \
          --user-agent "${userAgent}" \
          -o "$out" \
          "${url}"
      '';
    };
}
