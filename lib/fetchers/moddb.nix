{
  pkgs,
  fetchHtmlThenCurl,
  userAgent,
  ...
}:
{
  fetchModDB =
    {
      id,
      # `hash` matches sources.nix's field name (as update-sources.py
      # writes it), so a `sources.wad.<x>` attrset can be passed straight
      # through, same as fetchIdGames/fetchGitTree already allow; `sha256`
      # stays supported for existing call sites passing a literal directly.
      hash ? null,
      sha256 ? null,
      # sources.nix's recorded archive member list, when this source is a
      # pk3/archive -- attached as passthru so optimize/optimize' can
      # transparently extract/optimize/repack it without a caller needing
      # to pass this same sourceEntry again explicitly.
      archiveContent ? null,
      ...
    }:
    fetchHtmlThenCurl {
      name = "moddb-${toString id}";
      outputHash = if hash != null then hash else sha256;
      outputHashMode = "recursive";
      nativeBuildInputs = [
        pkgs.curl
        pkgs.gnused
      ];
      extract = true;
      extraAttrs.passthru.archiveContent = archiveContent;
      # moddb sits behind Cloudflare, whose bot-management flags nixpkgs'
      # curl (its TLS 1.3 ClientHello fingerprint) and returns 403;
      # capping at TLS 1.2 sidesteps that fingerprinting.
      resolve = ''
        resolved_path=$(curl --tls-max 1.2 --header "Referer: https://www.moddb.com/" --user-agent "${userAgent}" "https://www.moddb.com/downloads/start/${toString id}/all" \
        | sed -n 's/.*href="\(\/downloads\/mirror\/[^"]*\)".*/\1/p' | head -1)
        if [ -z "$resolved_path" ]; then
          echo "Error: could not find a /downloads/mirror/ link on moddb's download-start page for id ${toString id} (page layout changed, or a bot-check/error page was served instead)." >&2
          exit 1
        fi
        RESOLVED_URL="https://www.moddb.com$resolved_path"
      '';
      curlOpts = ''--tls-max 1.2 --header "Referer: https://www.moddb.com/" --user-agent "${userAgent}"'';
    };
}
