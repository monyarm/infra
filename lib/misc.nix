{ lib, ... }:
rec {
  # Must share the same thunk in both positions: builtins.parallel queues
  # arg1's list elements in the background, then forces arg2 on the main
  # thread -- a separately-written (even if identical-looking) expression
  # for arg2 doesn't reuse that work, it redoes it. Verified: sharing gave a
  # ~2.9x speedup on a real benchmark, duplicating was slower than plain
  # sequential map.
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

  # resolveExt is dispatchExt's matching logic without the "call it" step --
  # returns the matched handler *function* (or the "_" fallback function, or
  # null if neither exists), letting a caller that needs to invoke it with
  # something other than `src` (e.g. mkFormatDispatch's list-aware handlers)
  # reuse the exact same matching rules dispatchExt uses.
  resolveExt =
    extMap: src:
    let
      # Coerce to string, grab the basename, and force it to lowercase
      rawFileName = src.name or (builtins.baseNameOf (toString src));
      fileName = lib.toLower rawFileName;
      # Only used for "$"-prefixed exact-path keys -- falls back to the
      # basename for anything that isn't an archive member (getFile's
      # passthru.fullPath), so those keys are harmless no-ops elsewhere.
      fullPath = lib.toLower (src.fullPath or rawFileName);

      matchableAttrs = removeAttrs extMap [ "_" ];
      # Longest key first, not attrsToList's alphabetical order -- so a
      # compound suffix like ".psp.iso" or ".wii.iso" wins over the more
      # generic ".iso" it also happens to end with, regardless of which
      # one sorts first alphabetically (".psp.iso" sorts after ".iso" since
      # 'p' > 'i', which would otherwise make the generic key win first).
      matchableList = lib.sort (a: b: builtins.stringLength a.name > builtins.stringLength b.name) (
        lib.attrsToList matchableAttrs
      );

      # A key prefixed with "$" matches the item's full path exactly (e.g.
      # "$models/bloodspot/greenpool.png"), for one-off overrides on a
      # specific broken file -- checked against the full archive-relative
      # path, NOT just the basename, so it can't be confused with the "*"
      # prefix mode below. A key ending in "*" matches by basename PREFIX
      # instead of suffix (e.g. "decorate*" matches "DECORATE" and
      # "DECORATE.ChexMonsters") -- for GZDoom-style bare lump names with no
      # real trailing extension. Deliberately basename-only (not fullPath):
      # some of these lumps live under a subfolder (e.g.
      # "filter/doom.freedoom/decaldef.z"), whose full path doesn't start
      # with the lump name at all.
      matches = m:
        if lib.hasPrefix "$" m.name then
          fullPath == lib.toLower (lib.removePrefix "$" m.name)
        else if lib.hasSuffix "*" m.name then
          lib.hasPrefix (lib.toLower (lib.removeSuffix "*" m.name)) fileName
        else
          lib.hasSuffix (lib.toLower m.name) fileName;

      matched =
        lib.findFirst
          # The key (m.name) is checked against the lowercase filename
          matches
          null
          matchableList;
    in
    if matched != null then matched.value else extMap."_" or null;

  # dispatchExt accepts an attribute set where keys are extensions (e.g., ".zip")
  # and values are the functions handling them. Use "_" for a custom fallback.
  dispatchExt =
    extMap: src:
    let
      handler = resolveExt extMap src;
    in
    if handler != null then
      handler src
    else
      throw "dispatchExt: No matching handler found for extension in file '${lib.toLower (src.name or (builtins.baseNameOf (toString src)))}'";
}
