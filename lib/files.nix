{
  pkgs,
  lib,
  mkOutOfStoreSymlink,
  config,
  sanitizeName,
  getFileName,
  getName,
  parallel,
  dispatchExt,
  # Threaded so dynamic-inner.nix's sandboxed evaluation can pass
  # targetSystem: rename (below) runs once per file, and touching
  # pkgs.stdenv there would boot the whole bootstrap per archive. Outer
  # callers omit it and get the ambient value.
  system ? pkgs.stdenv.hostPlatform.system,
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
        inherit system;
        builder = "${pkgs.bash}/bin/bash";
        args = [
          "-c"
          ''
            ${pkgs.coreutils}/bin/cp -as "${drv}" "$out"
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
        passthru.archiveContent =
          folderDrv.archiveContent.${fileName} or (
            let
              # Recorded keys are literal zip-member names and may differ in
              # case from this entry's -- match case-insensitively.
              hit = lib.findFirst (k: lib.toLower k == lib.toLower fileName) null (
                builtins.attrNames (folderDrv.archiveContent or { })
              );
            in
            if hit == null then null else folderDrv.archiveContent.${hit} or null
          );
      }
      ''
        cp "${folderDrv}/${filePath}" "$out"
      '';

  splitFiles = fileList: _drv: parallel (map (file: getFile file _drv)) fileList;
  splitFilesWith =
    fileSpecs: drv:
    parallel (map (
      {
        file,
        transform ? (x: x),
        ...
      }:
      let
        extracted = getFile file drv;
      in
      if builtins.isList transform then
        lib.foldl' (value: operation: operation value) extracted transform
      else
        transform extracted
    )) fileSpecs;
  splitFilesBaseName =
    fileList: splitFiles (parallel (map (file: builtins.baseNameOf file)) fileList);

  # Glob pattern -> unanchored POSIX-extended regex body. The single
  # translation shared by fileListMatches (Nix side) and removeFiles'
  # find -iregex stage (shell side), so the recorded-list bookkeeping and
  # the actual deletion can't drift apart. caseInsensitive lowercases the
  # pattern; pair it with -iregex or toLower on the subject side.
  # [ ] - ! ^ pass through raw: they're only meaningful inside a [...]
  # class, same as in shell globs.
  globToRegex =
    {
      caseInsensitive ? false,
    }:
    p:
    lib.concatStringsSep "" (
      map (
        c:
        if c == "*" then
          ".*"
        else if c == "?" then
          "."
        else if
          lib.elem c [
            "["
            "]"
            "-"
            "!"
            "^"
          ]
        then
          c
        else
          lib.escapeRegex c
      ) (lib.stringToCharacters (if caseInsensitive then lib.toLower p else p))
    );

  # Like getFile, but keeps a whole subset of folderDrv as one folder.
  # Shared pattern-matching predicate for recorded file lists
  # (passthru.fileList): lets getFiles/removeFiles agree on what survives
  # without duplicating glob semantics. Patterns:
  #   literal        -> that path itself, plus everything under it
  #   *?[-class]glob -> glob with "/" matches the whole relpath
  #                     (case-sensitive, like shell expansion); a glob
  #                     WITHOUT "/" matches basenames case-insensitively
  #                     only when caseInsensitive is set (removeFiles
  #                     sets it; getFiles does not)
  #   dir!keep       -> everything under dir/ except basename keep, at any
  #                     depth (recursive find)
  fileListMatches =
    {
      caseInsensitive ? false,
    }:
    let
      norm = s: if caseInsensitive then lib.toLower s else s;
      globRe = p: "^" + globToRegex { inherit caseInsensitive; } p + "$";
      isGlob = p: lib.hasInfix "*" p || lib.hasInfix "?" p || lib.hasInfix "[" p;
      isKeep = p: lib.hasInfix "!" p;
    in
    e: p:
    if isKeep p then
      let
        parts = lib.splitString "!" p;
        dir = lib.head parts;
        keep = lib.last parts;
      in
      # Normalized like the find side (! -iname under $work/${dir}) so an
      # entry the shell actually kept isn't recorded as removed.
      lib.hasInfix "${norm dir}/" (norm e) && norm (builtins.baseNameOf e) != norm keep
    else if isGlob p then
      builtins.match (globRe p) (norm (if lib.hasInfix "/" p then e else builtins.baseNameOf e)) != null
    else
      norm e == norm p || lib.hasPrefix "${norm p}/" (norm e);

  # Entries can be files, directories (cp -a recurses), or shell glob
  # patterns (e.g. "app/DATA00[0-4].LAB"); matches land under their shared
  # dirname. IFS is cleared before expanding so spaces in real filenames
  # (unlike glob metachars) don't get word-split into separate arguments.
  getFiles =
    paths: folderDrv:
    let
      # Keep only the recorded-list fraction that survives into this
      # subset (selection semantics).
      fileListSubset =
        let
          orig = folderDrv.passthru.fileList or null;
          pred = fileListMatches { };
        in
        if orig == null then null else lib.filter (e: lib.any (pred e) paths) orig;
    in
    pkgs.runCommand "${sanitizeName folderDrv.name}-subset"
      (
        {
          __contentAddressed = true;
          allowSubstitutes = false;
          preferLocalBuild = true;
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
        }
        // lib.optionalAttrs (fileListSubset != null) { passthru.fileList = fileListSubset; }
      )
      ''
        mkdir -p "$out"
        ${lib.concatMapStringsSep "\n" (p: ''
          pattern=${lib.escapeShellArg p}
          destDir="$out/$(dirname -- "$pattern")"
          mkdir -p "$destDir"
          (
            IFS=
            set -- "${folderDrv}"/$pattern
            cp -as -- "$@" "$destDir/"
          )
        '') paths}
      '';

  # Inverse of getFiles: keeps everything except the listed files/
  # directories (missing entries are fine, rm -rf doesn't care). An entry
  # can also be "dir/!keep" to empty out dir/ while keeping just "keep"
  # inside it, or a glob ("*.dll" anywhere in the tree; "app/DATA[0-4]*"
  # against whole relpaths). The find stages implement exactly the
  # pattern language fileListMatches describes -- bare-basename globs via
  # -iname (fnmatch handles [classes] natively), "/"-globs via -iregex
  # over the relpath using the shared globToRegex translation -- so the
  # recorded-list mirror below can't claim (or miss) removals.
  # A separate step from whatever fetched folderDrv, so tweaking the list
  # doesn't require re-running a slow/networked fetch.
  removeFiles =
    paths: folderDrv:
    let
      isKeep = p: lib.hasInfix "!" p;
      hasMeta = p: lib.hasInfix "*" p || lib.hasInfix "?" p || lib.hasInfix "[" p;
      isBareGlob = p: !isKeep p && hasMeta p && !(lib.hasInfix "/" p);
      isPathGlob = p: !isKeep p && hasMeta p && lib.hasInfix "/" p;
      keepEntries = lib.filter isKeep paths;
      globEntries = lib.filter isBareGlob paths;
      pathGlobEntries = lib.filter isPathGlob paths;
      literalEntries = lib.filter (p: !isKeep p && !hasMeta p) paths;
      # Case-insensitive like the predicate (-iname on the dir resolves
      # "$work/<dir>" without a case-sensitive filesystem lookup).
      keepScript = lib.concatMapStringsSep "\n" (
        p:
        let
          parts = lib.splitString "!" p;
          dir = lib.removeSuffix "/" (lib.head parts);
          keep = lib.last parts;
        in
        ''find "$work" -type d -iname ${lib.escapeShellArg dir} -exec find '{}' -mindepth 1 ! -iname ${lib.escapeShellArg keep} -delete \; 2>/dev/null || true''
      ) keepEntries;
      # One tree walk for every glob, instead of one walk per glob -- with
      # dozens of cruft patterns applied to trees with huge file counts
      # (e.g. Last Express's per-frame TGA backgrounds), repeating the walk
      # per pattern dominated build time despite the work being disk-bound,
      # not CPU-bound.
      globScript = lib.optionalString (globEntries != [ ]) ''
        find "$work" \( ${
          lib.concatMapStringsSep " -o " (p: "-iname ${lib.escapeShellArg p}") globEntries
        } \) -delete 2>/dev/null || true
      '';
      # "/"-globs match whole relpaths: search from inside "$work" so the
      # printed paths are "./<relpath>" and the regex anchors cleanly.
      pathGlobScript = lib.optionalString (pathGlobEntries != [ ]) ''
        (
          cd "$work" && find . -regextype posix-extended \( ${
            lib.concatMapStringsSep " -o " (
              p: "-iregex ${lib.escapeShellArg ("\\./" + globToRegex { caseInsensitive = true; } p)}"
            ) pathGlobEntries
          } \) -delete 2>/dev/null || true
        )
      '';
      literalScript = lib.concatMapStringsSep "\n" (p: ''rm -rf -- "$work/${p}"'') literalEntries;

      # Mirror the removal patterns over the recorded list so downstream
      # handlerFiles filtering sees post-cruft extension reality. The
      # stages above implement this same predicate's semantics (see
      # removeFiles' docstring), so the two sides stay in lockstep.
      fileListFiltered =
        let
          orig = folderDrv.passthru.fileList or null;
          pred = fileListMatches { caseInsensitive = true; };
        in
        if orig == null then null else lib.filter (e: !(lib.any (pred e) paths)) orig;
    in
    pkgs.runCommand "${sanitizeName folderDrv.name}-pruned"
      (
        {
          __contentAddressed = true;
          allowSubstitutes = false;
          preferLocalBuild = true;
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
        }
        # Only attach passthru when there's a list to update -- keeps the
        # derivation byte-identical to pre-fileList behavior otherwise.
        // lib.optionalAttrs (fileListFiltered != null) { passthru.fileList = fileListFiltered; }
      )
      ''
        work="$TMPDIR/work"
        mkdir -p "$work"
        # -s: symlink file leaves instead of copying bytes -- cp -a was an
        # O(data size) full copy just to delete a few cruft files. chmod
        # stays dir-only since a recursive one would dereference into (and
        # mutate) the read-only symlinked sources.
        cp -as "${folderDrv}/." "$work/"
        find "$work" -type d -exec chmod u+w {} +
        ${keepScript}
        ${globScript}
        ${pathGlobScript}
        ${literalScript}
        cd /
        mv "$work" "$out"
      '';

  # Materializes a folder's symlinks (e.g. a linkFarm-style output) into
  # real byte copies, as its own cached CA derivation -- callers that need
  # dereferenced input get early cutoff: if folderDrv's content is
  # unchanged, this step (and anything built on top of its output) is
  # skipped entirely, no matter how many times/places it's asked for.
  # `cp --dereference` still hashes the *symlink's target text* if given
  # the symlink path itself unexpanded, so this copies from "$folderDrv/."
  # (trailing dot) to walk into it first.
  # `name`: optional override for the intermediate derivation's name. Needed
  # when folderDrv is a dynamic-derivation output (builtins.outputOf, e.g.
  # optimizeFolderDynamic's return) rather than a real derivation/store
  # path -- its string form is a bare CA placeholder hash, so getName's
  # fallback ("ca-file") would otherwise be all this step's name shows.
  derefSymlinks =
    {
      name ? null,
    }:
    folderDrv:
    # Raw `derivation`, not pkgs.runCommand -- same reasoning as packArchive
    # below: nested-archive processing inside the inner sandbox calls this
    # with the tool-overlay pkgs, where real-package construction (stdenv)
    # would read overlaid attrs like pkgs.gcc as sets.
    derivation {
      name = "${if name != null then name else getName folderDrv}-deref";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin
          mkdir -p "$out"
          cp -r --dereference --no-preserve=mode "${folderDrv}/." "$out/"
        ''
      ];
      __contentAddressed = true;
      allowSubstitutes = false;
      preferLocalBuild = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    };

  # Packs a folder's contents into a single archive named "<name>.<extension>".
  # `format` picks the archiver/compression scheme; `extension` (defaults to
  # `format`) is just the output filename's suffix, for formats like pk7/ipk3
  # that are really a well-known format under a different name. Assumes
  # folderDrv is already real bytes, no symlinks -- callers that might hand
  # in a symlink farm (e.g. archive.nix) run it through
  # `derefSymlinks` first, once, as its own cached step, rather than
  # every format branch here re-copying it inline on every repack.
  packArchive =
    {
      format,
      extension ? format,
    }:
    name: folderDrv:
    let
      byFormat = {
        "7z" = {
          pathEnv = "${pkgs.p7zip}/bin:${pkgs.coreutils}/bin";
          script = ''
            cd "$folderDrv"
            7z a -bd "$out" . >/dev/null
          '';
        };
        # Explicit -tzip, unlike "7z" above -- for repacking as a genuine
        # zip-format container (e.g. keeping a .pk3 a real .pk3), as opposed
        # to "7z"'s reliance on extension auto-detection falling back to
        # native 7z format for unrecognized extensions like .pk7/.ipk7.
        "zip" = {
          pathEnv = "${pkgs.p7zip}/bin:${pkgs.coreutils}/bin";
          script = ''
            cd "$folderDrv"
            7z a -tzip -bd "$out" . >/dev/null
          '';
        };
        "rpa" = {
          pathEnv = "${pkgs.rpatool}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin";
          script = ''
            cd "$folderDrv"
            rpatool -c "$out" -- $(find -L . -type f)
          '';
        };
      };
      chosen = byFormat.${format} or (throw "packArchive: unsupported format '${format}'");
    in
    # Raw `derivation`, not pkgs.runCommand -- same reasoning as
    # lib/optimize/handlers/archive.nix's stages: the inner sandbox's tool
    # overlays are store-path strings, and runCommand's stdenv machinery
    # constructs real packages (reading overlaid attrs like pkgs.gcc as
    # sets). PATH comes from the explicit export below instead of
    # buildInputs.
    derivation {
      name = "${name}.${extension}";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        (
          ''
            export PATH=${chosen.pathEnv}
          ''
          + chosen.script
        )
      ];
      inherit folderDrv;
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
      disallowedReferences = [ folderDrv ];
    };

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
