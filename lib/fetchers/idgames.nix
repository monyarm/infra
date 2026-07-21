{ pkgs, lib, ... }: {

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

      pname = if lib.isInt game then "idgames-${toString game}" else "idgames-${builtins.baseNameOf game}";

    in
    pkgs.stdenv.mkDerivation ({
      outputHashAlgo = "sha256";
      outputHash = hash;
      outputHashMode = "recursive";
      buildInputs = with pkgs;[
        curl
        jq
        unzip
        p7zip
      ];
      dontUnpack = true;
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      buildPhase = ''
        if [[ "${game}" =~ ^[0-9]+$ ]]; then
          id="${game}"
        else
          # if it's a path, extract the id from the path
          filePath="${game}"
          fileName=$(basename "$filePath")
        fi

        if [[ -n "$id" ]]; then
          apiResult = $(curl -L "https://www.doomworld.com/idgames/api/api.php?action=get&id=$id&out=json")
          dirPath = $(echo $apiResult | jq -r '.dir')
          fileName = $(echo $apiResult | jq -r '.filename')
          filePath="$dirPath/$fileName" 
        fi
        DOWNLOADED_FILE="$TMPDIR/$fileName"

        # Try mirrors sequentially until one succeeds
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

      installPhase = ''
        mkdir -p $out

        echo "Extracting specified target: $DOWNLOADED_FILE"

        case "$DOWNLOADED_FILE" in
          *.zip)
            unzip -q "$DOWNLOADED_FILE" -d $out
            ;;
          *.tar.gz|*.tgz)
            tar -xzf "$DOWNLOADED_FILE" -C $out
            ;;
          *.tar.xz|*.txz)
            tar -xJf "$DOWNLOADED_FILE" -C $out
            ;;
          *.rar|*.7z|*.exe)
            7z x "$DOWNLOADED_FILE" -o$out
            ;;
          *)
            echo "Raw wad, copy target directly to package layout root."
            cp "$DOWNLOADED_FILE" "$out/$(basename "$DOWNLOADED_FILE")"
            ;;
        esac
      '';
    }
      // (if version != null then { inherit version pname; } else {name = pname;})
    );
}
