{
  pkgs,
  fetchHtmlThenCurl,
  ...
}:
{
  fetchCurseForge =
    {
      modId,
      fileId,
      sha256,
      name ? "curseforge-${toString modId}-${toString fileId}",
    }:
    fetchHtmlThenCurl {
      inherit name;
      outputHash = sha256;
      outputHashMode = "recursive";
      useSecrets = true;
      nativeBuildInputs = [
        pkgs.curl
        pkgs.jq
      ];
      extract = true;
      resolve = ''
        if [ -z "''${CURSEFORGE_API_KEY:-}" ]; then
          echo "Error: CURSEFORGE_API_KEY is not set in the environment." >&2
          echo "Apply for a key at https://support.curseforge.com/support/solutions/articles/9000208346" >&2
          exit 1
        fi

        download_json=$(curl -fsSL -H "x-api-key: $CURSEFORGE_API_KEY" \
          "https://api.curseforge.com/v1/mods/${toString modId}/files/${toString fileId}/download-url")
        RESOLVED_URL=$(echo "$download_json" | jq -r '.data')
        if [ -z "$RESOLVED_URL" ] || [ "$RESOLVED_URL" = "null" ]; then
          echo "Error: could not resolve a curseforge download url for mod ${toString modId} file ${toString fileId}." >&2
          exit 1
        fi
      '';
    };
}
