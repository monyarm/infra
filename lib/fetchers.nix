{ pkgs, ... }:
let
  getFileNameFromUrl =
    url:
    let
      # Try to get query parameter (e.g., ?v=sFVJVWVDIMg)
      queryMatch = builtins.match ".*[?&]v=([^&]+).*" url;
      # Try to get last path segment (e.g., /video.mp4)
      pathMatch = builtins.match ".*/([^/]+)$" url;
    in
    if queryMatch != null then
      builtins.head queryMatch
    else if pathMatch != null then
      builtins.head pathMatch
    else
      "video";
in
{
  fetchProtonGE =
    version: hash:
    let
      name = "GE-Proton${version}";
    in
    pkgs.fetchzip {
      inherit name hash;
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${name}/${name}.tar.gz";
    };

  fetchVideo =
    {
      url,
      sha256,
      name ? getFileNameFromUrl url,
      audio ? false,
    }:
    pkgs.runCommand name
      {
        outputHashMode = "flat";
        outputHashAlgo = "sha256";
        outputHash = sha256;
        nativeBuildInputs = [ pkgs.yt-dlp ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        yt-dlp \
          ${if audio then "-f bestvideo+bestaudio" else "-f bestvideo"} \
          --no-playlist \
          --no-write-subs \
          --no-write-auto-subs \
          --no-write-info-json \
          --no-write-comments \
          -o "$out" \
          "${url}"
      '';

  fetchSteamStoreAsset =
    {
      appid,
      assetid,
      sha256,
      extension ? "jpg",
      name ? "${toString appid}-${assetid}.${extension}",
    }:
    pkgs.fetchurl {
      inherit name sha256;
      url = "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/${toString appid}/${assetid}.${extension}";
    };

  fetchPixiv =
    { url, sha256 }:
    pkgs.fetchurl {
      inherit sha256 url;
      curlOptsList = [
        "--header"
        "Referer: https://www.pixiv.net/"
      ];
    };
}
