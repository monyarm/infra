{
  pkgs,
  fetchHtmlThenCurl,
  ...
}:
{
  fetchNexus =
    {
      game,
      modId,
      fileId ? null,
      sha256,
      name ? "nexus-${game}-${toString modId}${if fileId != null then "-${toString fileId}" else ""}",
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
        if [ -z "''${NEXUS_API_KEY:-}" ]; then
          echo "Error: NEXUS_API_KEY is not set in the environment." >&2
          echo "Get a Premium API key at https://next.nexusmods.com/settings/api-keys" >&2
          echo "(unattended file downloads require a Premium account)." >&2
          exit 1
        fi

        fileId="${if fileId != null then toString fileId else ""}"
        if [ -z "$fileId" ]; then
          files_json=$(curl -fsSL -H "apikey: $NEXUS_API_KEY" \
            "https://api.nexusmods.com/v1/games/${game}/mods/${toString modId}/files.json?category=main,update")
          fileId=$(echo "$files_json" | jq -r '[.files[]] | sort_by(.uploaded_timestamp) | last | .file_id')
          if [ -z "$fileId" ] || [ "$fileId" = "null" ]; then
            echo "Error: could not resolve the latest nexus file for ${game}/${toString modId}." >&2
            exit 1
          fi
        fi

        download_json=$(curl -fsSL -H "apikey: $NEXUS_API_KEY" \
          "https://api.nexusmods.com/v1/games/${game}/mods/${toString modId}/files/$fileId/download_link.json")
        RESOLVED_URL=$(echo "$download_json" | jq -r '.[0].URI')
        if [ -z "$RESOLVED_URL" ] || [ "$RESOLVED_URL" = "null" ]; then
          echo "Error: could not resolve a nexus download link for ${game}/${toString modId}/$fileId." >&2
          echo "Note: unattended downloads via this endpoint require a Premium API key." >&2
          exit 1
        fi
      '';
    };
}
