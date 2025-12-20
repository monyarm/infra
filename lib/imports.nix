{
  pkgs,
  lib,
  ...
}:
rec {
  # Impurely decode and import a sops-encoded nix file at evaluation time
  importSopsNix =
    file:
    builtins.exec [
      "${pkgs.sops}/bin/sops"
      "--decrypt"
      (toString file)
    ];

  # Unified helper to import all files/directories in a given path
  # Automatically handles:
  # - .nix files (imported directly)
  # - .sops.nix files (decrypted and imported)
  # - directories with default.nix (imported as directory/default.nix)
  # - recursive traversal (when recursive=true)
  # Returns either a list of paths (for imports) or merged attrset (for combining modules)
  autoImport =
    pathOrArgs:
    let
      # If pathOrArgs is a path (string), convert to attrset with defaults
      args = if builtins.isAttrs pathOrArgs then pathOrArgs else { path = pathOrArgs; };

      inherit (args) path;
      importArgs = args.args or { };
      baseExclude = args.exclude or [ ];
      exclude = [ "default.nix" ] ++ baseExclude;
      mode = args.mode or "list";
      recursive = args.recursive or false;

      entries = builtins.readDir path;

      processEntry =
        name: type:
        let
          fullPath = path + "/${name}";
          isSopsFile = lib.hasSuffix ".sops.nix" name;
          isNixFile = lib.hasSuffix ".nix" name;
          isExcluded = builtins.elem name exclude;
        in
        if isExcluded then
          null
        else if type == "directory" then
          if lib.pathExists "${fullPath}/default.nix" then
            if mode == "list" then "${fullPath}/default.nix" else import "${fullPath}/default.nix" importArgs
          else if recursive then
            # Recursively process subdirectory
            let
              subResults = autoImport {
                path = fullPath;
                args = importArgs;
                inherit
                  baseExclude
                  mode
                  recursive
                  ;
              };
            in
            subResults
          else
            null
        else if type == "regular" && isNixFile then
          if isSopsFile then
            if mode == "list" then
              # For list mode, decrypt the file to get the path
              importSopsNix fullPath
            else
              # For merge mode, decrypt and call with importArgs
              (importSopsNix fullPath) importArgs
          else if mode == "list" then
            fullPath
          else
            import fullPath importArgs
        else
          null;

      processed = lib.mapAttrsToList processEntry entries;
      filtered = lib.filter (x: x != null) processed;
      # Flatten the list if recursive mode is enabled (since subdirectories return lists/attrsets)
      flattened = if recursive then lib.flatten filtered else filtered;
    in
    if mode == "list" then flattened else lib.foldl' (acc: val: acc // val) { } flattened;
}
