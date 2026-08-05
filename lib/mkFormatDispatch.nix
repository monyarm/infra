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
    else
      h;

  handlers = lib.listToAttrs (
    map (name: {
      inherit name;
      value = normalizeHandler (import (handlersDir + "/${name}.nix") commonArgs);
    }) canonicalNames
  );

  passthroughHandler = normalizeHandler (if listAware then srcs: srcs else src: src);
  handlersWithPassthrough = handlers // {
    _ = passthroughHandler;
  };

  aliasHandlers = lib.listToAttrs (
    lib.flatten (
      lib.mapAttrsToList (
        handlerName: aliasNames:
        map (aliasName: lib.nameValuePair aliasName handlersWithPassthrough.${handlerName}) aliasNames
      ) aliases
    )
  );

  resolvedHandlers = handlers // aliasHandlers // { _ = passthroughHandler; };

  pickHandler =
    prime: primeOverride: name: h:
    if primeOverride.${name} or prime then h.prime else h.normal;

  # "$"/"*"-prefixed alias names pass through as-is, not dot-prefixed (see
  # lib/misc.nix's resolveExtSorted).
  mkDispatchMap =
    prime: primeOverride:
    lib.mapAttrs' (
      name: h:
      lib.nameValuePair (if lib.hasPrefix "$" name || lib.hasSuffix "*" name then name else ".${name}") (
        pickHandler prime primeOverride name h
      )
    ) resolvedHandlers;

  toList = x: if builtins.isList x then x else [ x ];

  dispatchMapNormal = mkDispatchMap false { };
  dispatchMapPrime = mkDispatchMap true { };
  dispatchMapNormalSorted = sortDispatchKeys dispatchMapNormal;
  dispatchMapPrimeSorted = sortDispatchKeys dispatchMapPrime;

  # Mirrors optimize/default.nix's cachedDispatchMap/cachedSortedKeys.
  cached =
    normalV: primeV: computeFn: prime: primeOverride:
    if primeOverride == { } then (if prime then primeV else normalV) else computeFn prime primeOverride;
  cachedDispatchMap = cached dispatchMapNormal dispatchMapPrime mkDispatchMap;
  cachedSortedKeys = cached dispatchMapNormalSorted dispatchMapPrimeSorted (
    prime: primeOverride: sortDispatchKeys (mkDispatchMap prime primeOverride)
  );

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
      primeOverride ? { },
      fallback,
      extra ? null,
    }:
    x:
    if builtins.isList x then
      map (run {
        inherit
          prime
          primeOverride
          fallback
          extra
          ;
      }) x
    else
      let
        realMap = cachedDispatchMap prime primeOverride;
        sortedKeys = cachedSortedKeys prime primeOverride;
        dispatchMap = realMap // { "_" = fallback; };
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
