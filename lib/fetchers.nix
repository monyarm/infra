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
      inherit (functions)
        fetchzipNoSubst
        fetchGitTree
        secretsPrelude
        extractArchiveSnippet
        fetchToolOutput
        fetchHtmlThenCurl
        downloadNamedUrls
        fetchWithReferrer
        ;
    })
  ) { } (builtins.attrNames (builtins.readDir ./fetchers));

  functions =

    rec {

      secretsPrelude = useSecrets: if useSecrets then "source /secrets" else "";

      # file/outDir are raw (unquoted) shell expressions, e.g.
      # `file = "$DOWNLOADED_FILE"; outDir = "$out";` — this snippet quotes them.
      extractArchiveSnippet =
        { file, outDir }:
        ''
          # .pk3/.ipk3/.pk7/.ipk7 are zip-format containers that GZDoom loads
          # as a single opaque file (via -file or as an iwad); they must be
          # kept intact rather than unzipped, even though they mime-sniff as
          # application/zip.
          case "${file}" in
            *.[pP][kK]3 | *.[iI][pP][kK]3 | *.[pP][kK]7 | *.[iI][pP][kK]7)
              echo "Detected a pk3/pk7 container, keeping it as a single file."
              ${pkgs.coreutils}/bin/cp "${file}" "${outDir}/$(${pkgs.coreutils}/bin/basename "${file}")"
              ;;
            *)
              filetype=$(${pkgs.file}/bin/file -b --mime-type "${file}")
              echo "Detected mime type: $filetype"
              case "$filetype" in
                application/zip)
                  ${pkgs.unzip}/bin/unzip -q "${file}" -d "${outDir}"
                  ;;
                application/gzip | application/x-gzip)
                  ${pkgs.gnutar}/bin/tar -xzf "${file}" -C "${outDir}"
                  ;;
                application/x-xz)
                  ${pkgs.gnutar}/bin/tar -xJf "${file}" -C "${outDir}"
                  ;;
                application/x-rar)
                  # p7zip's bundled rar codec fails on some real-world RAR
                  # files ("Can not open the file as archive"); unrar handles
                  # them correctly.
                  ${pkgs.unrar}/bin/unrar x -o+ "${file}" "${outDir}/"
                  ;;
                application/x-7z-compressed | application/x-dosexec)
                  ${pkgs.p7zip}/bin/7z x "${file}" -o"${outDir}"
                  ;;
                *)
                  echo "Raw file, copying directly."
                  ${pkgs.coreutils}/bin/cp "${file}" "${outDir}/$(${pkgs.coreutils}/bin/basename "${file}")"
                  ;;
              esac
              ;;
          esac
        '';

      fetchToolOutput =
        {
          name,
          outputHash,
          outputHashMode ? "recursive",
          nativeBuildInputs ? [ ],
          useSecrets ? false,
          extraAttrs ? { },
          script,
        }:
        pkgs.runCommand name
          (
            {
              inherit
                outputHash
                outputHashMode
                nativeBuildInputs
                ;
              outputHashAlgo = "sha256";
            }
            // extraAttrs
          )
          ''
            ${secretsPrelude useSecrets}
            ${script}
          '';

      # `resolve` must set $RESOLVED_URL for this function to curl itself, or
      # set $DOWNLOADED_FILE directly if it already fetched the file (e.g. a
      # mirror-fallback loop that has to curl each candidate to test it).
      fetchHtmlThenCurl =
        {
          name,
          outputHash,
          outputHashMode ? "flat",
          nativeBuildInputs ? [ pkgs.curl ],
          useSecrets ? false,
          extraAttrs ? { },
          resolve,
          curlOpts ? "",
          extract ? false,
        }:
        pkgs.runCommand name
          (
            {
              inherit
                outputHash
                outputHashMode
                nativeBuildInputs
                ;
              outputHashAlgo = "sha256";
              SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
            }
            // extraAttrs
          )
          ''
            set -e
            ${secretsPrelude useSecrets}
            ${resolve}
            if [ -z "''${DOWNLOADED_FILE:-}" ]; then
              DOWNLOADED_FILE="$TMPDIR/downloaded"
              curl -fL ${curlOpts} "$RESOLVED_URL" -o "$DOWNLOADED_FILE"
            fi
            ${
              if extract then
                ''
                  mkdir -p "$out"
                  ${extractArchiveSnippet {
                    file = "$DOWNLOADED_FILE";
                    outDir = "$out";
                  }}
                ''
              else if outputHashMode == "recursive" then
                ''
                  mkdir -p "$out"
                  OUT_NAME=$(basename "''${RESOLVED_URL%%\?*}")
                  cp "$DOWNLOADED_FILE" "$out/$OUT_NAME"
                ''
              else
                ''
                  cp "$DOWNLOADED_FILE" "$out"
                ''
            }
          '';

      # Per-file failures are non-fatal (some assets may not exist).
      downloadNamedUrls =
        files: outDirExpr:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            fname: url:
            ''curl -fsSL "${url}" -o "${outDirExpr}/${fname}" || echo "Warning: ${fname} not available" >&2''
          ) files
        );

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
      fetchWithReferrer =
        referrer:
        { url, sha256 }:
        pkgs.fetchurl {
          inherit sha256 url;
          curlOptsList = [
            "--header"
            "Referer: ${referrer}"
            "--user-agent"
            userAgent
          ];
        };

    };
in
functions // subdirImports
