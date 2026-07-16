{
  pkgs,
  dirs,
  importSopsString,
  urlEncode,
  splitFiles,
  getFileNameFromUrl,
  ...
}:
let
  inherit (pkgs) lib;
  userAgent = "Mozilla/5.0 (X11; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0";
  subdirImports = builtins.foldl' (
    acc: file:
    acc
    // (import ./fetchers/${file} {
      inherit
        pkgs
        lib
        dirs
        importSopsString
        urlEncode
        splitFiles
        getFileNameFromUrl
        userAgent
        ;
      inherit (functions) fetchzipNoSubst;
    })
  ) { } (builtins.attrNames (builtins.readDir ./fetchers));

  functions =

    rec {

      fetchzipNoSubst =
        args:
        (pkgs.fetchzip args).overrideAttrs (_oldAttrs: {
          allowSubstitutes = false;
        });

      fetchzipSelective =
        {
          keepFiles,
          flatten ? false,
          ...
        }@args:
        let
          # 1. Strip our custom arguments so fetchzip doesn't complain about unexpected inputs
          fetchzipArgs = removeAttrs args [
            "keepFiles"
            "flatten"
          ];

          # 2. Define our custom post-processing shell script
          selectivePostFetch = ''
            STAGING=$(mktemp -d)

            # Extract specified files/dirs to staging safely
            ${pkgs.lib.concatMapStringsSep "\n" (file: ''
              if [ -e "$out/${file}" ]; then
                mkdir -p "$STAGING/$(dirname "${file}")"
                cp -r "$out/${file}" "$STAGING/${file}"
              else
                echo "Warning: keepFiles entry '${file}' was not found in the fetched archive!"
              fi
            '') keepFiles}

            # Clear target directory completely
            rm -rf $out/*

            if [ "${pkgs.lib.boolToString flatten}" = "true" ]; then
              # Deep Flatten: Find every file/symlink and copy to the root of $out/
              find "$STAGING" -type f -o -type l | while IFS= read -r file; do
                # Optional: warn on collisions
                filename=$(basename "$file")
                if [ -e "$out/$filename" ]; then
                  echo "Warning: Flattening collision! Overwriting $out/$filename with $file"
                fi
                cp -dp "$file" "$out/"
              done
            else
              # Preserve exact relative structures
              cp -pr "$STAGING"/. "$out/"
            fi

            rm -rf "$STAGING"
          '';
        in
        # 3. Use overrideAttrs to APPEND our script to whatever postFetch fetchzip already runs
        (fetchzipNoSubst fetchzipArgs).overrideAttrs (oldAttrs: {
          postFetch = (oldAttrs.postFetch or "") + "\n" + selectivePostFetch;
          stripRoot = false;
        });
      fetchChaosium =
        {
          game,
          name,
          hash ? "",
        }:
        pkgs.fetchurl {
          url = "https://www.chaosium.com/content/Backgrounds/${urlEncode game}%20Background%20-%20${urlEncode name}.jpg";
          inherit hash;
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
            ;
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

      fetchWithReferrer =
        referrer:
        {
          url,
          sha256 ? null,
          hash ? sha256,
        }:
        pkgs.fetchurl {
          inherit hash url;
          curlOptsList = [
            "--header"
            "Referer: ${referrer}"
            "--user-agent"
            userAgent
          ];
        };

      fetchPixiv = fetchWithReferrer "https://www.pixiv.net/";
      fetchGelbooru =
        args:
        fetchWithReferrer "https://gelbooru.com/" (
          args
          // {
            url = builtins.replaceStrings [
              "https://img.gelbooru.com/"
              "https://img1.gelbooru.com/"
              "https://img2.gelbooru.com/"
              "https://img3.gelbooru.com/"
            ] (lib.lists.replicate 4 "https://img4.gelbooru.com/") args.url;
          }
        );
      fetchSteamGrid =
        {
          id,
          hash ? "",
          sha256 ? "",
        }:

        pkgs.runCommand "steamgriddb-${toString id}"
          {
            # Fixed-output derivation parameters to allow network access
            outputHashAlgo = if hash != "" then null else "sha256";
            outputHash = if hash != "" then hash else sha256;

            # Native dependencies
            nativeBuildInputs = [
              pkgs.curl
              pkgs.gnused
              pkgs.gnugrep
            ];
          }
          ''
            referrer="https://www.steamgriddb.com/grid/${toString id}"
            echo "Fetching page metadata from: $referrer"

            # 1. Fetch the HTML page
            curl -s -H "User-Agent: ${userAgent}" "$referrer" > page.html

            # 2. Parse the download URL from the asset-download block
            img_url=$(grep -A 1 'class="asset-download"' page.html | sed -n 's|.*href="\([^"]*\)".*|\1|p' | head -n 1)

            if [ -z "$img_url" ]; then
              echo "Error: Could not extract download URL from SteamGridDB page."
              exit 1
            fi

            echo "Found direct image link: $img_url"

            # 3. Download the actual image directly to $out
            curl -L -H "User-Agent: ${userAgent}" -H "Referer: $referrer" "$img_url" -o "$out"
          '';
    };
in
functions // subdirImports
