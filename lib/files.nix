{
  pkgs,
  lib,
  mkOutOfStoreSymlink,
  config,
  sanitizeName,
  getFileName,
  parallel,
  dispatchExt,
  ...
}:
rec {
  getSecretPath = name: config.sops.secrets."${name}".path;

  binFile =
    content:
    let
      originalName =
        content.pname
          or (content.name or (builtins.baseNameOf (builtins.unsafeDiscardStringContext content)));
      parts = lib.splitString "." originalName;
      extensionsToRemove = [
        "sh"
        "zsh"
        "pm1"
        "csh"
        "py"
        "pyc"
        "pyo"
        "lua"
        "nims"
        "awk"
        "bat"
        "js"
        "ts"
        "php"
        "pl"
        "r"
        "elf"
        "bs"
        "cmd"
        "bin"
        "vb"
        "vbs"
        "vbscript"
        "app"
        "com"
        "command"
        "jar"
      ];
      name =
        if lib.length parts > 1 && lib.elem (lib.toLower (lib.last parts)) extensionsToRemove then
          lib.concatStringsSep "." (lib.init parts)
        else
          originalName;
    in
    {
      ".local/bin/${name}" = {
        source = content;
        executable = true;
      };
    };

  binFiles = list: parallel (lib.foldl (acc: value: acc // (binFile value)) { }) list;

  linkImpl =
    targetSubfolder: linkContents: fileList:
    let
      resolveSource =
        source:
        if lib.isDerivation source then
          source
        else if (lib.isString source || builtins.isPath source) then
          let
            s = toString source;
            isStorePath = lib.hasPrefix builtins.storeDir (builtins.unsafeDiscardStringContext s);
          in
          if isStorePath then
            source # already in the store (context intact) — pass through, no wrapper needed
          else if lib.hasPrefix "/" s then
            mkOutOfStoreSymlink (builtins.unsafeDiscardStringContext s) # genuine external path, safe to strip
          else
            source
        else
          source;

      processItem =
        item:
        let
          name =
            if lib.isAttrs item && !lib.isDerivation item then
              lib.elemAt (builtins.attrNames item) 0
            else if lib.isDerivation item then
              item.pname or item.name
            else if (builtins.isPath item || lib.isString item) then
              builtins.baseNameOf (builtins.unsafeDiscardStringContext item) # Required, because baseNameOf requires a blank string context
            else if lib.isAttrs item && item ? name then
              item.name
            else
              throw "Invalid item type for name extraction: ${builtins.typeOf item}";

          # 1. Extract the raw item first (without coercing derivations to strings!)
          rawSrc =
            if lib.isAttrs item && !lib.isDerivation item then
              lib.elemAt (builtins.attrValues item) 0
            else
              item;

          # 2. Pass the raw item to resolveSource.
          # Because we don't force a string here, a derivation stays a derivation!
          src = resolveSource rawSrc;
        in
        {
          name = "${targetSubfolder}/${name}";
          value = {
            source = src;
            recursive = !linkContents;
          };
        };

      processedList =
        if linkContents then
          lib.flatten (
            parallel (map (
              path:
              let
                # Convert a derivation object to its string store path explicitly
                # so that pathIsDirectory can safely evaluate it on your disk.
                targetPath = if lib.isDerivation path then path.outPath else path;
              in
              if lib.pathIsDirectory targetPath then
                if lib.isDerivation path then
                  # DERIVATION FOLDERS: Map explicitly using string interpolation.
                  # This injects the live context directly into each generated file string,
                  # bypassing listFilesRecursive's context stripping and fixing your stale updates.
                  map (name: "${path}/${name}") (builtins.attrNames (builtins.readDir targetPath))
                else
                  # LOCAL DIRECTORIES: Use your original recursive utility function safely
                  listFilesRecursive targetPath
              else
                # SINGLE FILES (Derivations, paths, or normal strings)
                [ path ]
            )) fileList
          )
        else
          fileList;
    in
    lib.listToAttrs (parallel (map processItem) processedList);

  linkFiles = targetSubfolder: fileList: linkImpl targetSubfolder false fileList;

  linkContents = targetSubfolder: fileList: linkImpl targetSubfolder true fileList;

  mkOutOfStoreSymlinkRecursive =
    sourcePath:
    let
      derivedTargetPrefix = builtins.baseNameOf (builtins.toString sourcePath);
      isPathADirectory =
        p:
        let
          readResult = builtins.tryEval (builtins.readDir p);
        in
        readResult.success && builtins.isAttrs readResult.value;
      collectEntries =
        currentSourcePath: currentRelativePath:
        if builtins.isString currentSourcePath then
          if isPathADirectory currentSourcePath then
            let
              dirContents = builtins.readDir currentSourcePath;
              processedItems = lib.flatten (
                lib.mapAttrsToList (
                  name: type:
                  let
                    subSourcePath = currentSourcePath + "/${name}";
                    subRelativePath = currentRelativePath + "/${name}";
                  in
                  if type == "directory" then
                    collectEntries subSourcePath subRelativePath
                  else if type == "regular" || type == "symlink" then
                    [
                      {
                        source = subSourcePath;
                        relativeTarget = subRelativePath;
                      }
                    ]
                  else
                    [ ]
                ) dirContents
              );
            in
            processedItems
          else
            [
              {
                source = currentSourcePath;
                relativeTarget = currentRelativePath;
              }
            ]
        else
          throw "mkOutOfStoreSymlinkRecursive: Invalid path encountered: ${currentSourcePath} (type: ${builtins.typeOf currentSourcePath})";
      allCollectedEntries = collectEntries sourcePath ""; # Initial call with empty relative path
    in
    lib.listToAttrs (
      parallel (map (
        entry:
        let
          value =
            if entry ? isDir && entry.isDir then
              { source = null; }
            else
              { source = mkOutOfStoreSymlink entry.source; };
          finalName = lib.strings.concatStringsSep "/" [
            derivedTargetPrefix
            (lib.strings.removePrefix "/" entry.relativeTarget) # Remove leading slash if present
          ];
        in
        {
          name = finalName;
          inherit value;
        }
      )) allCollectedEntries
    );

  listFilesRecursive =
    path:
    let
      # --- 1. Pure Nix Folder Scanner ---
      scanPure =
        p:
        let
          files = builtins.readDir p;
          items = builtins.attrNames files;
        in
        parallel (builtins.concatMap (
          item:
          let
            newPath = p + /${item};
            isDir = (builtins.getAttr item files) == "directory";
          in
          if isDir then scanPure newPath else [ newPath ]
        )) items;

      # --- 2. Build-Time Manifest Scanner (CA/IFD Fallback) ---
      scanViaIFD =
        folderSrc:
        let
          safeName = builtins.unsafeDiscardStringContext (baseNameOf (toString folderSrc));

          manifest =
            pkgs.runCommand "${safeName}-dir-manifest.nix"
              {
                preferLocalBuild = true;
                allowSubstitutes = false;
                __contentAddressed = true;
                outputHashAlgo = "sha256";
                outputHashMode = "flat";
                src = folderSrc;
              }
              ''
                echo "[" > $out
                cd "$src"
                # Find files, sort them, and write them purely as relative strings
                find . -type f | sort | while read -r file; do
                  clean_file=$(echo "$file" | sed 's|^\./||')
                  # Outputting just a raw string like: "subfolder/file.png"
                  # This contains NO store path references, keeping the CA derivation happy!
                  echo "  \"$clean_file\"" >> $out
                done
                echo "]" >> $out
              '';

          # Import the list of relative strings
          relativeFiles = import manifest;
        in
        # Reconstruct the absolute paths in pure Nix.
        # Appending the relative string to the 'folderSrc' variable ensures
        # that the string context (dependency tracking) is perfectly retained!
        parallel (map (rel: folderSrc + "/${rel}")) relativeFiles;

      asPath =
        p:
        if builtins.isPath p then
          p
        else
          builtins.storePath (builtins.unsafeDiscardStringContext (toString p));
    in
    if builtins.hasContext (toString path) then scanViaIFD path else scanPure (asPath path);

  rename =
    src: drv:
    if (toString src) == (toString drv) then
      src
    else
      derivation {
        name = sanitizeName (getFileName src); # clean original name, e.g. "photo.jpg"
        inherit (pkgs.stdenv.hostPlatform) system;
        builder = "${pkgs.bash}/bin/bash";
        args = [
          "-c"
          ''
            ${pkgs.coreutils}/bin/cp "${drv}" "$out"
            exit 0; # fix for 2176?
          ''
        ];
        # Not preferLocalBuild: this runs at the end of every optimize
        # pipeline (src |> pipelineMap |> rename src), same reasoning as
        # guardSize -- the actual optimization work is already free to run
        # remotely, so pinning just this trailing cp local would drag it
        # back for no reason.
        allowSubstitutes = false;
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      };

  getFile =
    filePath: folderDrv:
    let
      fileName = builtins.baseNameOf filePath;
    in
    pkgs.runCommand fileName
      {
        # Not preferLocalBuild: getFile is called constantly throughout the
        # optimize/fetch chains (pk3 member extraction, etc.) -- same
        # back-and-forth reasoning as guardSize/rename.
        allowSubstitutes = false;
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        # Nix silently sanitizes derivation names (e.g. spaces -> hyphens),
        # so `.name` on the result can differ from the real on-disk
        # filename -- callers that need the exact original (matching e.g. a
        # sources.nix-recorded key) should use `.originalName` instead.
        passthru.originalName = fileName;
        # The full path this file had inside folderDrv (e.g. an archive
        # member's "MODELS/BloodSpot/greenpool.png"), not just its basename
        # -- dispatchExt's "$"-prefixed exact-path keys match against this.
        passthru.fullPath = filePath;
        # If folderDrv itself carries a recorded archive member list (e.g.
        # a gdrive/moddb/mediafire/itch fetch of a folder containing this
        # pk3), and this file is one of the pk3s/archives it lists, forward
        # that file's own member list so optimize/optimize' can recognize
        # and handle it as an archive transparently too, without needing
        # this same lookup done again at every call site.
        passthru.archiveContent = folderDrv.archiveContent.${fileName} or null;
      }
      ''
        cp "${folderDrv}/${filePath}" "$out"
      '';

  splitFiles = fileList: _drv: parallel (map (file: getFile file _drv)) fileList;
  splitFilesBaseName =
    fileList: splitFiles (parallel (map (file: builtins.baseNameOf file)) fileList);

  # Like getFile, but keeps a whole subset of folderDrv as one folder.
  # Entries can be files, directories (cp -a recurses), or shell glob
  # patterns (e.g. "app/DATA00[0-4].LAB"); matches land under their shared
  # dirname. IFS is cleared before expanding so spaces in real filenames
  # (unlike glob metachars) don't get word-split into separate arguments.
  getFiles =
    paths: folderDrv:
    pkgs.runCommand "${sanitizeName folderDrv.name}-subset"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p "$out"
        ${lib.concatMapStringsSep "\n" (p: ''
          pattern=${lib.escapeShellArg p}
          destDir="$out/$(dirname -- "$pattern")"
          mkdir -p "$destDir"
          (
            IFS=
            set -- "${folderDrv}"/$pattern
            cp -a -- "$@" "$destDir/"
          )
        '') paths}
      '';

  # Inverse of getFiles: keeps everything except the listed files/
  # directories (missing entries are fine, rm -rf doesn't care). An entry
  # can also be "dir/!keep" to empty out dir/ while keeping just "keep"
  # inside it. A separate step from whatever fetched folderDrv, so tweaking
  # the list doesn't require re-running a slow/networked fetch.
  removeFiles =
    paths: folderDrv:
    pkgs.runCommand "${sanitizeName folderDrv.name}-pruned"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        work="$TMPDIR/work"
        mkdir -p "$work"
        cp -a "${folderDrv}/." "$work/"
        chmod -R u+w "$work"
        ${lib.concatMapStringsSep "\n" (
          p:
          if lib.hasInfix "!" p then
            let
              parts = lib.splitString "!" p;
              dir = lib.removeSuffix "/" (lib.head parts);
              keep = lib.last parts;
            in
            ''find "$work/${dir}" -mindepth 1 ! -name ${lib.escapeShellArg keep} -delete 2>/dev/null || true''
          else
            ''rm -rf -- "$work/${p}"''
        ) paths}
        cd /
        mv "$work" "$out"
      '';

  # Packs a folder's contents into a single archive named "<name>.<extension>".
  # `format` picks the archiver/compression scheme; `extension` (defaults to
  # `format`) is just the output filename's suffix, for formats like pk7/ipk3
  # that are really a well-known format under a different name.
  packArchive =
    {
      format,
      extension ? format,
    }:
    name: folderDrv:
    let
      byFormat = {
        "7z" = {
          buildInputs = [ pkgs.p7zip ];
          script = ''
            # A symlink-farm folder (e.g. linkFarm output) has its entries
            # archived as the link target string rather than its contents
            # unless dereferenced into real copies first.
            cp -rL "${folderDrv}" ./repack-real
            cd repack-real
            7z a -bd "$out" . >/dev/null
          '';
        };
        # Explicit -tzip, unlike "7z" above -- for repacking as a genuine
        # zip-format container (e.g. keeping a .pk3 a real .pk3), as opposed
        # to "7z"'s reliance on extension auto-detection falling back to
        # native 7z format for unrecognized extensions like .pk7/.ipk7.
        "zip" = {
          buildInputs = [ pkgs.p7zip ];
          script = ''
            cp -rL "${folderDrv}" ./repack-real
            cd repack-real
            7z a -tzip -bd "$out" . >/dev/null
          '';
        };
      };
      chosen = byFormat.${format} or (throw "packArchive: unsupported format '${format}'");
    in
    pkgs.runCommand "${name}.${extension}"
      {
        buildInputs = chosen.buildInputs;
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      chosen.script;

  patchFile =
    let
      caAttrs = {
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      };
      flipsHandler =
        p: f:
        pkgs.runCommand (lib.getName f) ({ nativeBuildInputs = [ pkgs.flips ]; } // caAttrs) ''
          flips --apply "${p}" "${f}" "$out"
        '';
      xdeltaHandler =
        p: f:
        pkgs.runCommand (lib.getName f) ({ nativeBuildInputs = [ pkgs.xdelta ]; } // caAttrs) ''
          xdelta3 -d -s "${f}" "${p}" "$out"
        '';
      patchHandler =
        p: f:
        pkgs.runCommand (lib.getName f) ({ nativeBuildInputs = [ pkgs.gnupatch ]; } // caAttrs) ''
          patch "${f}" -i "${p}" -o "$out"
        '';
    in
    patch: file:
    dispatchExt {
      ".ips" = flipsHandler;
      ".bps" = flipsHandler;
      ".xdelta" = xdeltaHandler;
      ".vcdiff" = xdeltaHandler;
      ".diff" = patchHandler;
      ".patch" = patchHandler;
      "_" =
        p: _f:
        throw "patchFile: unsupported patch format for '${p.name or (toString p)}' (supported: ips, bps, xdelta, vcdiff, diff, patch)";
    } patch file;
}
