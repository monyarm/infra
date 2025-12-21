{
  lib,
  mkOutOfStoreSymlink,
  config,
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

  binFiles = list: lib.foldl (acc: value: acc // (binFile value)) { } list;

  linkImpl =
    targetSubfolder: linkContents: fileList:
    let
      resolveSource =
        source:
        if lib.isDerivation source then
          "${source}"
        else if (lib.isString source || builtins.isPath source) && lib.hasPrefix "/" source then
          mkOutOfStoreSymlink source # Absolute path, not store path
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

          src = resolveSource (
            if lib.isAttrs item && !lib.isDerivation item then lib.elemAt (builtins.attrValues item) 0 else item
          );
        in
        {
          name = "${targetSubfolder}/${name}";
          value = {
            source = src;
            recursive = true;
          };
        };

      processedList =
        if linkContents then
          lib.flatten (
            lib.map (path: if lib.pathIsDirectory path then listFilesRecursive path else [ path ]) fileList
          )
        else
          fileList;
    in
    lib.listToAttrs (lib.map processItem processedList);

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
      lib.map (
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
      ) allCollectedEntries
    );

  listFilesRecursive =
    path:
    let
      cleanPath =
        if builtins.isAttrs path && path ? "type" && path.type == "derivation" then
          builtins.unsafeDiscardStringContext (toString path)
        else
          toString path;

      list =
        p:
        let
          files = builtins.readDir p;
          items = builtins.attrNames files;
        in
        builtins.concatMap (
          item:
          let
            newPath = p + "/" + item;
            isDir = (builtins.getAttr item files) == "directory";
          in
          if isDir then list newPath else [ newPath ]
        ) items;
    in
    list cleanPath;
}
