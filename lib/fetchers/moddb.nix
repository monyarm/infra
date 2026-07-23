{
  pkgs,
  fetchHtmlThenCurl,
  userAgent,
  ...
}:
{
  fetchModDB =
    { id, sha256 }:
    fetchHtmlThenCurl {
      name = "moddb-${toString id}";
      outputHash = sha256;
      outputHashMode = "recursive";
      nativeBuildInputs = [
        pkgs.curl
        pkgs.gnused
      ];
      extract = true;
      # moddb sits behind Cloudflare, whose bot-management flags nixpkgs'
      # curl (its TLS 1.3 ClientHello fingerprint) and returns 403;
      # capping at TLS 1.2 sidesteps that fingerprinting.
      resolve = ''
        resolved_path=$(curl --tls-max 1.2 --header "Referer: https://www.moddb.com/" --user-agent "${userAgent}" "https://www.moddb.com/downloads/start/${toString id}/all" \
        | sed -n 's/.*href="\/\([^"]*\)".*/\1/p' | head -1)
        RESOLVED_URL="https://www.moddb.com/$resolved_path"
      '';
      curlOpts = ''--tls-max 1.2 --header "Referer: https://www.moddb.com/" --user-agent "${userAgent}"'';
    };
}
