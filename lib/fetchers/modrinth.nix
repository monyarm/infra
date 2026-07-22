{
  pkgs,
  fetchHtmlThenCurl,
  ...
}:
{
  fetchModrinth =
    {
      project,
      versionId ? null,
      filename ? null,
      sha256,
      name ? "modrinth-${project}",
    }:
    let
      selectVersionJq =
        if versionId != null then
          ''.[] | select(.id == "${versionId}")''
        else
          ''sort_by(.date_published) | last'';
      selectFileJq =
        if filename != null then
          ''((.files[] | select(.filename == "${filename}")) // .files[0])''
        else
          ''((.files[] | select(.primary)) // .files[0])'';
    in
    fetchHtmlThenCurl {
      inherit name;
      outputHash = sha256;
      outputHashMode = "flat";
      nativeBuildInputs = [
        pkgs.curl
        pkgs.jq
      ];
      resolve = ''
        version_json=$(curl -fsSL "https://api.modrinth.com/v2/project/${project}/version" | jq -c '${selectVersionJq}')
        if [ -z "$version_json" ] || [ "$version_json" = "null" ]; then
          echo "Error: could not resolve a modrinth version for project '${project}'." >&2
          exit 1
        fi

        RESOLVED_URL=$(echo "$version_json" | jq -r '${selectFileJq} | .url')
        if [ -z "$RESOLVED_URL" ] || [ "$RESOLVED_URL" = "null" ]; then
          echo "Error: could not resolve a download url from modrinth version metadata." >&2
          exit 1
        fi
      '';
    };
}
