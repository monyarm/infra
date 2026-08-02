{ lib, resolveExt, ... }:
# Generalizes the folder-scan/alias/dispatch pattern lib/optimize/default.nix
# pioneered (discover one handler file per canonical extension, resolve
# aliases onto them, dispatch by filename, pick prime vs normal) so
# lib/compressRom/ can reuse it.
#
# listAware controls only the synthesized passthrough handler's shape --
# every *real* handler function comes straight from `import file
# commonArgs` untouched, so whether it takes a single src or a srcs list is
# entirely up to what's actually in handlersDir. lib/compressRom/'s
# handlers take srcs (listAware = true, the default); lib/optimize/'s 20+
# existing per-extension files take a single src and don't change
# (listAware = false), since optimize/default.nix builds its own
# pipelineMap on top of mkDispatchMap rather than using `run`.
{
  handlersDir,
  commonArgs,
  aliases,
  listAware ? true,
  # "default.nix" (the file doing the importing) is always excluded from
  # the handler scan; callers with other plumbing files living alongside
  # their handlers (e.g. optimize/'s bulk.nix/text.nix) add to this list.
  excludeNames ? [ "default.nix" ],
}:
let
  handlerFileNames = builtins.filter (
    n: lib.hasSuffix ".nix" n && !(builtins.elem n excludeNames)
  ) (builtins.attrNames (builtins.readDir handlersDir));
  canonicalNames = map (n: lib.removeSuffix ".nix" n) handlerFileNames;

  normalizeHandler = h: if lib.isFunction h then { prime = h; normal = h; } else h;

  handlers = lib.listToAttrs (
    map (name: {
      inherit name;
      value = normalizeHandler (import (handlersDir + "/${name}.nix") commonArgs);
    }) canonicalNames
  );

  passthroughHandler = normalizeHandler (if listAware then srcs: srcs else src: src);
  handlersWithPassthrough = handlers // { _ = passthroughHandler; };

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

  # The base per-extension (dot-prefixed) dispatch map, same shape
  # optimize/default.nix's pipelineMap uses -- exposed so a caller with its
  # own extra dispatch entries (exact-name keys, its own fallback) can merge
  # them in before calling dispatchExt itself.
  #
  # An alias name already prefixed with "$" or suffixed with "*"
  # (resolveExt's exact-whole-path and basename-prefix match modes, see
  # lib/misc.nix) is passed through as-is, not dot-prefixed -- e.g.
  # optimize/default.nix's aliases._ lists "$bigfont" for a lump with no
  # extension at all, and aliases.decorate lists "decorate*" to also match
  # bare/dot-suffixed lump variants like "DECORATE"/"DECORATE.ChexMonsters"
  # alongside the plain ".decorate" dot-extension form.
  mkDispatchMap =
    prime: primeOverride:
    lib.mapAttrs' (
      name: h:
      lib.nameValuePair
        (if lib.hasPrefix "$" name || lib.hasSuffix "*" name then name else ".${name}")
        (pickHandler prime primeOverride name h)
    ) resolvedHandlers;

  toList = x: if builtins.isList x then x else [ x ];

  # Named-parts attrset keys that are only ever *siblings*, never the thing
  # that identifies the format on its own -- excluded from the generic
  # key-name dispatch scan below. Without this, `{ cue = ...; bin = [...]; }`
  # would wrongly match on "bin" before "cue" (builtins.attrNames sorts
  # alphabetically, and "bin" also happens to be a real registered
  # extension alias in its own right, for raw Genesis/MegaDrive roms).
  auxiliaryAttrKeys = [ "ips" "bps" "ups" "bin" "tracks" ];

  # `run { prime; primeOverride; fallback; extra; } x`, where `x` is one of:
  #
  # - A list -- maps `run` over each element independently and returns a
  #   *list* of results. No "primary among siblings" concept anymore: every
  #   entry is its own independent dispatch.
  # - An attrset that isn't a derivation (named parts, e.g. `{ rom = ...;
  #   ips = ...; }` or `{ cue = ...; bin = [...]; }`) -- resolved to a
  #   handler one of two ways: if it has a `rom` key, dispatch by that
  #   key's own filename extension (exactly like a bare src); otherwise,
  #   the first attrset key whose *name* exactly matches a real registered
  #   dispatch key (e.g. `cue`/`gdi`, already real keys via aliases.chd)
  #   wins. No per-handler declarations needed -- this reuses the existing
  #   alias table as-is. The whole attrset is passed to the resolved
  #   handler either way, not just the matched key's value.
  # - A bare derivation (or anything else) -- dispatches on its own
  #   filename, same as today, and is passed to the handler as-is (not
  #   wrapped in a list).
  #
  # Every handler (including `fallback`) is called uniformly as
  # `extra: x: ...` -- `extra` is opaque to this function (e.g.
  # compressRom's `parent`); handlers that don't care just ignore it.
  run =
    {
      prime ? false,
      primeOverride ? { },
      fallback,
      extra ? null,
    }:
    x:
    if builtins.isList x then
      map (run { inherit prime primeOverride fallback extra; }) x
    else
      let
        dispatchMap = (mkDispatchMap prime primeOverride) // { "_" = fallback; };
        realMap = removeAttrs dispatchMap [ "_" ];
        isNamedParts = builtins.isAttrs x && !(lib.isDerivation x);
        handler =
          if !isNamedParts then
            resolveExt dispatchMap x
          else if x ? rom then
            resolveExt dispatchMap x.rom
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
