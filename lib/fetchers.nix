{
  pkgs,
  dirs,
  importSopsString,
  urlEncode,
  splitFiles,
  getFileNameFromUrl,
  sources,
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
        sources
        ;
      inherit (functions) fetchzipNoSubst fetchGitTree;
    })
  ) { } (builtins.attrNames (builtins.readDir ./fetchers));

  functions =

    rec {

      fetchGitTree =
        {
          url,
          rev,
          hash ? null,
          sha1 ? null,
          name ? "${lib.sources.urlToName url}-git-${args.date or rev}",
          ...
        }@args:
        let
          targetHash =
            if hash != null then
              hash
            else if sha1 != null then
              sha1
            else
              throw "fetchGitTree: You must provide either 'hash' or 'sha1'";

          # Filter out our custom arguments
          cleanArgs = removeAttrs args [
            "url"
            "rev"
            "hash"
            "sha1"
            "name"
            "files"
          ];

          # Since we don't have stdenv, we build our own basic PATH
          binPath = pkgs.lib.makeBinPath [
            pkgs.git
            pkgs.coreutils
          ];
        in
        derivation (
          cleanArgs
          // {
            inherit name;

            # Explicitly choose the execution platform
            system = args.system or pkgs.stdenv.hostPlatform.system;

            # Tell Nix we are running an RFC0133 Git-Hashed FOD
            outputHashMode = "git";
            outputHashAlgo = "sha1";
            outputHash = targetHash;

            # Bare-metal derivations require you to explicitly pass the builder executable and its args
            builder = "${pkgs.bash}/bin/bash";
            args = [
              "-e" # Exit on any command failure
              (pkgs.writeText "fetch-git-tree-builder.sh" ''
                # Set up our bare-metal environment path
                export PATH="${binPath}"
                export GIT_SSL_CAINFO="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

                # 1. Initialize cleanly
                git init -q --template=/var/empty "$out"
                cd "$out"

                git config advice.detachedHead false
                git config advice.defaultBranchName false

                # 2. Add remote and fetch quietly
                git remote add origin "${url}"
                git -c core.hooksPath=/dev/null fetch --progress --depth 1 origin "${rev}" 2>&1

                # 3. Checkout files
                git -c core.hooksPath=/dev/null reset --hard  FETCH_HEAD

                # # 4. If submodules exist, fetch them recursively
                # if [ -f .gitmodules ]; then
                #   git submodule update --init --recursive
                # fi

                # 5. Cleanup git metadata
                rm -rf .git
              '')
            ];
          }
        );

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

      fetchModDB =
        {
          id,
          sha256 ? null,
          hash ? sha256,
        }:
        pkgs.runCommand "moddb-${toString id}"
          {
            outputHashAlgo = "sha256";
            outputHash = hash;
            outputHashMode = "recursive";

            # Native dependencies
            nativeBuildInputs = [
              pkgs.curl
              pkgs.gnused
              pkgs.gnugrep
              pkgs.unzip
              pkgs.gnutar
              pkgs.p7zip
              pkgs.file
            ];
            SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          }
          ''
            OUTDIR=$TMPDIR/out
            mkdir -p "$OUTDIR"
            DOWNLOADED_FILE="$OUTDIR/download"

            resolved_url=$(curl --header "Referer: https://www.moddb.com/" --user-agent "${userAgent}" "https://www.moddb.com/downloads/start/${toString id}/all" \
            | sed -n 's/.*href="\/\([^"]*\)".*/\1/p' | head -1)
            curl --header "Referer: https://www.moddb.com/" --user-agent "${userAgent}" -L -C - "https://www.moddb.com/$resolved_url" -o "$DOWNLOADED_FILE"

            mkdir -p $out
            echo "Extracting specified target: $DOWNLOADED_FILE"

            filetype=$(file -b --mime-type "$DOWNLOADED_FILE")
            echo "Detected mime type: $filetype"

            case "$filetype" in
              application/zip)
                unzip -q "$DOWNLOADED_FILE" -d $out
                ;;
              application/gzip|application/x-gzip)
                tar -xzf "$DOWNLOADED_FILE" -C $out
                ;;
              application/x-xz)
                tar -xJf "$DOWNLOADED_FILE" -C $out
                ;;
              application/x-rar|application/x-7z-compressed|application/x-dosexec)
                7z x "$DOWNLOADED_FILE" -o"$out"
                ;;
              *)
                echo "Raw binary, copy target directly to package layout root."
                origname=$(basename "$resolved_url")
                cp "$DOWNLOADED_FILE" "$out/''${origname:-download}"
                ;;
            esac
          '';
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
