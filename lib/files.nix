{
  pkgs,
  lib,
  mkOutOfStoreSymlink,
  config,
  sanitizeName,
  getFileName,
  parallel,
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
        preferLocalBuild = true;
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
        preferLocalBuild = true;
        allowSubstitutes = false;
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        cp "${folderDrv}/${filePath}" "$out"
      '';

  splitFiles = fileList: _drv: parallel (map (file: getFile file _drv)) fileList;
  splitFilesBaseName =
    fileList: splitFiles (parallel (map (file: builtins.baseNameOf file)) fileList);

  patchIps =
    patch: file:
    let
      patchExt = lib.toLower (lib.last (lib.splitString "." (lib.getName patch)));
    in
    pkgs.runCommand (lib.getName file)
      {
        nativeBuildInputs = [
          pkgs.flips # handles .ips and .bps
          pkgs.xdelta # handles .xdelta / .vcdiff
        ];
      }
      (
        if patchExt == "ips" || patchExt == "bps" then
          ''
            flips --apply "${patch}" "${file}" "$out"
          ''
        else if patchExt == "xdelta" || patchExt == "vcdiff" then
          ''
            xdelta3 -d -s "${file}" "${patch}" "$out"
          ''
        else
          throw "patchIps: unsupported patch format '.${patchExt}' (supported: ips, bps, xdelta, vcdiff)"
      );
}
