{
  pkgs,
  fetchHtmlThenCurl,
  ...
}:
{
  fetchModIO =
    {
      game,
      modId,
      fileId ? null,
      sha256,
      name ? "modio-${toString game}-${toString modId}${if fileId != null then "-${toString fileId}" else ""}",
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
        if [ -z "''${MODIO_API_KEY:-}" ]; then
          echo "Error: MODIO_API_KEY is not set in the environment." >&2
          exit 1
        fi

        fileId="${if fileId != null then toString fileId else ""}"
        if [ -z "$fileId" ]; then
          files_json=$(curl -fsSL "https://api.mod.io/v1/games/${toString game}/mods/${toString modId}/files?api_key=$MODIO_API_KEY")
          file_json=$(echo "$files_json" | jq -c '[.data[]] | sort_by(.date_added) | last')
        else
          file_json=$(curl -fsSL "https://api.mod.io/v1/games/${toString game}/mods/${toString modId}/files/$fileId?api_key=$MODIO_API_KEY")
        fi

        # mod.io's binary_url signature expires shortly after this metadata is
        # fetched, so it must be curled immediately rather than cached.
        RESOLVED_URL=$(echo "$file_json" | jq -r '.download.binary_url')
        if [ -z "$RESOLVED_URL" ] || [ "$RESOLVED_URL" = "null" ]; then
          echo "Error: could not resolve a mod.io download url for game ${toString game} mod ${toString modId}." >&2
          exit 1
        fi
      '';
    };
}
