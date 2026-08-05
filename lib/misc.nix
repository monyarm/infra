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

  # Longest key first, so ".psp.iso" wins over ".iso". "_" excluded (fallback).
  # Split out so callers can sort once and reuse via resolveExtSorted.
  sortDispatchKeys =
    extMap:
    lib.sort (a: b: builtins.stringLength a.name > builtins.stringLength b.name) (
      lib.attrsToList (removeAttrs extMap [ "_" ])
    );

  # dispatchExt's matching logic, minus the call -- returns the handler (or
  # "_" fallback, or null). Takes the pre-sorted list separately from
  # extMap (needed whole for "_" lookup) instead of re-sorting every call.
  resolveExtSorted =
    matchableList: extMap: src:
    let
      rawFileName = src.name or (builtins.baseNameOf (toString src));
      fileName = lib.toLower rawFileName;
      fullPath = lib.toLower (src.fullPath or rawFileName);

      # "$..." matches the full path exactly (one-off override for a
      # specific broken file). "...*" matches by basename PREFIX, not
      # suffix -- for bare GZDoom lump names like "DECORATE".
      matches =
        m:
        if lib.hasPrefix "$" m.name then
          fullPath == lib.toLower (lib.removePrefix "$" m.name)
        else if lib.hasSuffix "*" m.name then
          lib.hasPrefix (lib.toLower (lib.removeSuffix "*" m.name)) fileName
        else
          lib.hasSuffix (lib.toLower m.name) fileName;

      matched = lib.findFirst matches null matchableList;
    in
    if matched != null then matched.value else extMap."_" or null;

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
        lib.toLower (src.name or (builtins.baseNameOf (toString src)))
      }'";

  # dispatchExt accepts an attribute set where keys are extensions (e.g., ".zip")
  # and values are the functions handling them. Use "_" for a custom fallback.
  dispatchExt = extMap: dispatchExtSorted (sortDispatchKeys extMap) extMap;
}
