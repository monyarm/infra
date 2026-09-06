{ lib, ... }:
rec {
  # Must share the same thunk in both args -- a separate expression redoes
  # the work instead of reusing it. ~2.9x speedup verified.
  parallel =
    func: args:
    let
      result = func args;
    in
    builtins.parallel args result;

  parallelZipListsWith =
    f: a: b:
    let
      result = lib.zipListsWith f a b;
    in
    builtins.parallel b result;

  # Longest name wins across all kinds (prefix "decorate*" beats suffix
  # ".txt"). Was a linear scan, biggest per-file cost (trace-function-calls).
  # Bucketed by length instead, hashmap lookup per kind.
  sortDispatchKeys =
    extMap:
    let
      normalized = map (
        m:
        if lib.hasPrefix "$" m.name then
          {
            kind = "exact";
            compareStr = lib.toLower (lib.removePrefix "$" m.name);
            rawLen = builtins.stringLength m.name;
            inherit (m) value;
          }
        else if lib.hasSuffix "*" m.name then
          {
            kind = "prefix";
            compareStr = lib.toLower (lib.removeSuffix "*" m.name);
            rawLen = builtins.stringLength m.name;
            inherit (m) value;
          }
        else
          {
            kind = "suffix";
            compareStr = lib.toLower m.name;
            rawLen = builtins.stringLength m.name;
            inherit (m) value;
          }
      ) (lib.attrsToList (removeAttrs extMap [ "_" ]));
      byLength = lib.groupBy (e: toString e.rawLen) normalized;
      mapOfKind =
        kind: es:
        builtins.listToAttrs (
          map (e: lib.nameValuePair e.compareStr e.value) (lib.filter (e: e.kind == kind) es)
        );
      lengthBuckets = lib.mapAttrs (_: es: {
        exactMap = mapOfKind "exact" es;
        suffixMap = mapOfKind "suffix" es;
        prefixMap = mapOfKind "prefix" es;
      }) byLength;
      sortedLengths = lib.sort (a: b: a > b) (lib.unique (map (e: e.rawLen) normalized));
    in
    {
      inherit lengthBuckets sortedLengths;
    };

  # Strips a leading store-path hash ("<32 chars>-") if present. Duplicated
  # from (not shared with) lib/strings.nix's own stripStoreHash: strings.nix
  # itself depends on this file for `parallel`, so the reverse dependency
  # would be circular.
  stripStoreHash =
    name:
    if builtins.match "[a-z0-9]{32}-.*" name != null then
      builtins.substring 33 (builtins.stringLength name) name
    else
      name;

  # dispatchExt's matching logic, minus the call -- returns the handler (or
  # "_" fallback, or null). Takes the pre-sorted list separately from
  # extMap (needed whole for "_" lookup) instead of re-sorting every call.
  resolveExtSorted =
    matchableList: extMap: src:
    let
      # A "known file" src (dynamic-inner.nix's per-archive-member dispatch)
      # is a bare builtins.path value with no .name attribute, so this falls
      # back to baseNameOf (toString src) -- which, unlike a derivation's
      # .name, always carries a leading store hash. Left unstripped, that
      # hash silently breaks every "name*" prefix-matched alias (e.g.
      # decorate's own comment: "matches bare DECORATE and
      # DECORATE.ChexMonsters"), since the hash sits before the real name.
      rawFileName = stripStoreHash (src.name or (builtins.baseNameOf (toString src)));
      # Stripped: .${...} needs context-free keys. src (context intact)
      # reaches the handler, not these.
      fileName = builtins.unsafeDiscardStringContext (lib.toLower rawFileName);
      fullPath = builtins.unsafeDiscardStringContext (lib.toLower (src.fullPath or rawFileName));

      fileNameLen = builtins.stringLength fileName;
      fullPathLen = builtins.stringLength fullPath;

      # markedLen = l - 1: exact/prefix compareStr had its "$"/"*" marker
      # stripped, suffix didn't.
      tryLength =
        lengths:
        if lengths == [ ] then
          null
        else
          let
            l = builtins.head lengths;
            markedLen = l - 1;
            bucket = matchableList.lengthBuckets.${toString l};
            exactHit = if markedLen == fullPathLen then bucket.exactMap.${fullPath} or null else null;
            suffixHit =
              if l <= fileNameLen then
                bucket.suffixMap.${builtins.substring (fileNameLen - l) l fileName} or null
              else
                null;
            prefixHit =
              if markedLen >= 0 && markedLen <= fileNameLen then
                bucket.prefixMap.${builtins.substring 0 markedLen fileName} or null
              else
                null;
          in
          if exactHit != null then
            exactHit
          else if suffixHit != null then
            suffixHit
          else if prefixHit != null then
            prefixHit
          else
            tryLength (builtins.tail lengths);

      matched = tryLength matchableList.sortedLengths;
    in
    if matched != null then matched else extMap."_" or null;

  resolveExt = extMap: resolveExtSorted (sortDispatchKeys extMap) extMap;

  # Same split as resolveExtSorted/resolveExt, one layer up: calls the handler.
  dispatchExtSorted =
    matchableList: extMap: src:
    let
      handler = resolveExtSorted matchableList extMap src;
    in
    if handler != null then
      handler src
    else
      throw "dispatchExt: No matching handler found for extension in file '${
        lib.toLower (stripStoreHash (src.name or (builtins.baseNameOf (toString src))))
      }'";

  # dispatchExt accepts an attribute set where keys are extensions (e.g., ".zip")
  # and values are the functions handling them. Use "_" for a custom fallback.
  dispatchExt = extMap: dispatchExtSorted (sortDispatchKeys extMap) extMap;
}
