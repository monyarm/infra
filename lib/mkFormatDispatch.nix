{
  lib,
  resolveExtSorted,
  sortDispatchKeys,
  ...
}:
# Generalizes lib/optimize/default.nix's discover/alias/dispatch pattern so
# lib/compressRom/ can reuse it.
#
# listAware: passthrough handler shape only. compressRom's handlers take
# srcs (true, default); optimize's take a single src (false).
{
  handlersDir,
  commonArgs,
  aliases,
  listAware ? true,
  excludeNames ? [ "default.nix" ],
}:
let
  handlerFileNames = builtins.filter (n: lib.hasSuffix ".nix" n && !(builtins.elem n excludeNames)) (
    builtins.attrNames (builtins.readDir handlersDir)
  );
  canonicalNames = map (n: lib.removeSuffix ".nix" n) handlerFileNames;

  normalizeHandler =
    h:
    if lib.isFunction h then
      {
        prime = h;
        normal = h;
      }
    # A handler file may export `handler = ...;` alongside `extensions`
    # instead of separate `normal`/`prime`, when it doesn't distinguish the
    # two -- same effect as a bare function, but still able to also declare
    # `extensions` (a bare function can't, since `extensions` needs an
    # attrset to live on).
    else if h ? handler then
      h
      // {
        prime = h.handler;
        normal = h.handler;
      }
    else
      h;

  rawHandlers = lib.listToAttrs (
    map (name: {
      inherit name;
      value = import (handlersDir + "/${name}.nix") commonArgs;
    }) canonicalNames
  );
  handlers = lib.mapAttrs (_: normalizeHandler) rawHandlers;

  # A handler file may export `extensions = [...]` alongside {normal;
  # prime;} to self-register its own dispatch keys, instead of the caller
  # also having to list them in its own `aliases` table.
  declaredAliases = lib.mapAttrs (
    _: h: if lib.isAttrs h then (h.extensions or [ ]) else [ ]
  ) rawHandlers;
  combinedAliases = lib.zipAttrsWith (_: lib.concatLists) [
    declaredAliases
    aliases
  ];

  passthroughHandler = normalizeHandler (if listAware then srcs: srcs else src: src);
  handlersWithPassthrough = handlers // {
    _ = passthroughHandler;
  };

  aliasHandlers = lib.listToAttrs (
    lib.flatten (
      lib.mapAttrsToList (
        handlerName: aliasNames:
        map (aliasName: lib.nameValuePair aliasName handlersWithPassthrough.${handlerName}) aliasNames
      ) combinedAliases
    )
  );

  resolvedHandlers = handlers // aliasHandlers // { _ = passthroughHandler; };

  pickHandler =
    prime: _name: h:
    if prime then h.prime else h.normal;

  # "$"/"*"-prefixed alias names pass through as-is, not dot-prefixed (see
  # lib/misc.nix's resolveExtSorted).
  mkDispatchMap =
    prime:
    lib.mapAttrs' (
      name: h:
      lib.nameValuePair (if lib.hasPrefix "$" name || lib.hasSuffix "*" name then name else ".${name}") (
        pickHandler prime name h
      )
    ) resolvedHandlers;

  toList = x: if builtins.isList x then x else [ x ];

  dispatchMapNormal = mkDispatchMap false;
  dispatchMapPrime = mkDispatchMap true;
  dispatchMapNormalSorted = sortDispatchKeys dispatchMapNormal;
  dispatchMapPrimeSorted = sortDispatchKeys dispatchMapPrime;

  # Mirrors optimize/default.nix's cachedDispatchMap/cachedSortedKeys.
  cachedDispatchMap = prime: if prime then dispatchMapPrime else dispatchMapNormal;
  cachedSortedKeys = prime: if prime then dispatchMapPrimeSorted else dispatchMapNormalSorted;

  # Sibling keys, never format-identifying -- excluded from the dispatch
  # scan below, or `{ cue; bin = [...]; }` wrongly matches "bin" first.
  auxiliaryAttrKeys = [
    "ips"
    "bps"
    "ups"
    "bin"
    "tracks"
  ];

  # `x`: list -> map independently. Named-parts attrset -> dispatch by
  # `.rom`'s extension, or first key matching a registered dispatch key.
  # Anything else -> dispatch by its own filename. Handlers called as
  # `extra: x: ...`; `extra` is opaque (e.g. compressRom's `parent`).
  run =
    {
      prime ? false,
      fallback,
      extra ? null,
    }:
    x:
    if builtins.isList x then
      map (run {
        inherit
          prime
          fallback
          extra
          ;
      }) x
    else
      let
        realMap = cachedDispatchMap prime;
        sortedKeys = cachedSortedKeys prime;
        dispatchMap = realMap // {
          "_" = fallback;
        };
        isNamedParts = builtins.isAttrs x && !(lib.isDerivation x);
        handler =
          if !isNamedParts then
            resolveExtSorted sortedKeys dispatchMap x
          else if x ? rom then
            resolveExtSorted sortedKeys dispatchMap x.rom
          else
            let
              candidateKeys = lib.subtractLists auxiliaryAttrKeys (builtins.attrNames x);
              matchedKey = lib.findFirst (k: realMap ? ".${k}") null candidateKeys;
            in
            if matchedKey != null then realMap.".${matchedKey}" else fallback;
      in
      handler extra x;
in
{
  inherit
    handlers
    resolvedHandlers
    pickHandler
    mkDispatchMap
    toList
    run
    ;
}
