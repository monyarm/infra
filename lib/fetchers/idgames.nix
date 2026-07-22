{
  pkgs,
  lib,
  fetchHtmlThenCurl,
  ...
}:
{

  fetchIdGames =
    {
      game,
      hash,
      version ? null,
      ...
    }:
    let
      mirrors = [
        "ftp.fu-berlin.de/pc/games/idgames"
        "youfailit.net/pub/idgames"
        "ftpmirror.infania.net/pub/idgames"
        "mirror.braindrainlan.nu/pub/idgames"
        "files.xvertigox.com/idgames"
        "lethe.chinstrap.org/idgames"
        "mirrors.lug.mtu.edu/idgames"
        "gamers.org/pub/idgames"
      ];

      pname =
        if lib.isInt game then "idgames-${toString game}" else "idgames-${builtins.baseNameOf game}";
      name = if version != null then "${pname}-${version}" else pname;

      # Resolving the file path is fully known at Nix-eval time (either the
      # numeric idgames id or the literal mirror-relative path), so this
      # branches in Nix rather than re-checking it with a runtime bash regex.
      resolveFilePath =
        if lib.isInt game then
          ''
            id="${toString game}"
            apiResult=$(curl -L "https://www.doomworld.com/idgames/api/api.php?action=get&id=$id&out=json")
            dirPath=$(echo "$apiResult" | jq -r '.dir')
            fileName=$(echo "$apiResult" | jq -r '.filename')
            filePath="$dirPath/$fileName"
          ''
        else
          ''
            filePath="${game}"
            fileName=$(basename "$filePath")
          '';
    in
    fetchHtmlThenCurl {
      inherit name;
      outputHash = hash;
      outputHashMode = "recursive";
      nativeBuildInputs = [
        pkgs.curl
        pkgs.jq
      ];
      extract = true;
      resolve = ''
        ${resolveFilePath}

        DOWNLOADED_FILE="$TMPDIR/$fileName"
        for mirror in ${lib.concatStringsSep " " mirrors}; do
          url="https://$mirror/$filePath"
          echo "Attempting to fetch from $url"
          if curl -fL "$url" -o "$DOWNLOADED_FILE"; then
            echo "Successfully fetched from $url"
            break
          else
            echo "Failed to fetch from $url, trying next mirror..."
          fi
        done
      '';
    };
}
