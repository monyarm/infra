{
  pkgs,
  lib,
  getName,
  rename,
  resolveExtSorted,
  sortDispatchKeys,
  packArchive,
  derefSymlinks,
  # Threaded so the sandboxed inner evaluation (dynamic-inner.nix) can pass
  # targetSystem instead of touching pkgs.stdenv -- constructing real stdenv
  # there boots the whole bootstrap for every archive. Outer callers omit it
  # and get the ambient value.
  system ? pkgs.stdenv.hostPlatform.system,
  nixWasmRustPath ? null,
  # Pre-built lib/wasm/dispatch .wasm, built outside dynamic-inner.nix's
  # sandbox (see dynamic.nix's toolPathsJSON) and passed as a store path.
  # Only forced if batchResolveDispatch is actually called.
  dispatchWasmPath ? (throw "dispatchWasmPath is required by batchResolveDispatch"),
  # Same module, as a directory (undereferenced) -- threaded into a nested
  # optimizeFolderDynamic call so it skips rebuilding from ../wasm.nix
  # source. Unlike dispatchWasmPath above, genuinely optional: null at the
  # real top-level call (nothing built yet there).
  dispatchWasmDir ? null,
  ...
}:

let
  # jpeg/wad/deh/decorate/glsl/obj/c self-register aliases via their own
  # handler's `extensions = [...]` (lib/mkFormatDispatch.nix's
  # declaredAliases). Only the unowned generic passthrough bucket lives here.
  aliases = {
    # bin/ir: GDCC build artifacts, passthrough only.
    _ = [
      "unknown"
      "txt"
      "md2"
      "md3"
      "raw"
      "o"
      "bin"
      "ir"
      "dat"
      "$thumbs.db"
      # trackers/SPC700/IVF, used well beyond Doom -- stays global
      "spc"
      "it"
      "s3m"
      "xm"
      "psm"
      "mptm"
      "ivf"
      "pcx" # rare, not worth a re-encoder
      "kvx" # Build-engine voxel, no lossless re-encoder available
      "bmp"
      "tmp"
      "op2"
    ];
  };

  # Doom-lump-specific passthrough, unlike `aliases._` above -- only
  # registered while doom context is active (see doomDispatch below), so
  # a same-named file outside a pk3 still hits the "no optimizer" trace.
  doomAliases = {
    _ = [
      "lmp"
      "lump"
      "fon2" # extensionless FON2 lumps
      "$bigfont"
      "$smallfnt"
      "$zeldfnt2"
      "pal"
      "cmp" # explicitly PLAYPAL/COLORMAP lump names
      "dbs" # Doom Builder's own per-map editor settings, never loaded by GZDoom
      "qc" # MilkShape/Quake3 MD3 build script, never loaded by GZDoom
    ];
  };

  guardSize =
    originalDrv: src:
    derivation {
      name = "${originalDrv.name}-g";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          origSize=$(${pkgs.coreutils}/bin/stat -L -c%s "${src}")
          optSize=$(${pkgs.coreutils}/bin/stat -L -c%s "${originalDrv}")
          if [ "$optSize" -gt "$origSize" ]; then
            ${pkgs.coreutils}/bin/cp "${src}" "$out"
          else
            ${pkgs.coreutils}/bin/cp "${originalDrv}" "$out"
          fi
          exit 0;
        ''
      ];
      # Not preferLocalBuild: keep the compare-and-pick step remote, or
      # every chained stage's output gets dragged home and re-uploaded.
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      # __noChroot = true;
    };

  # guardSize inlined as a handler script's last line, not a wrapping
  # derivation. Handlers must use `cmd ... || rm -f candidate` (never bare
  # `|| true`), or a crash can leave a truncated candidate this can't catch.
  # Curried on candidate so a caller that partially applies once per
  # candidate name (e.g. png.nix's shared "tmp.png") pays setup once.
  guardSizeTail =
    candidate:
    let
      coreutilsBin = "${pkgs.coreutils}/bin";
      candidateStr = "${candidate}";
    in
    src: ''
      if [ -s "${candidateStr}" ] && [ "$(${coreutilsBin}/stat -L -c%s "${candidateStr}")" -le "$(${coreutilsBin}/stat -L -c%s "${src}")" ]; then
        ${coreutilsBin}/cp "${candidateStr}" "$out"
      else
        ${coreutilsBin}/cp "${src}" "$out"
      fi
    '';

  # Shared by mp3/ogg/wma/wav: lossless metadata strip via ffmpeg stream
  # copy. -fflags +bitexact also drops ffmpeg's own encoder tag.
  ffmpegStripMetadata =
    ext: src:
    derivation {
      name = "${getName src}-stripped.${ext}";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.ffmpeg-headless}/bin
          ffmpeg -y -i "${src}" -map_metadata -1 -fflags +bitexact -c copy tmp.${ext} || rm -f tmp.${ext}
          ${guardSizeTail "tmp.${ext}" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };

  # Shared by png.nix's lossless chain and ico.nix's per-frame loop -- same
  # tools/flags, run against different filenames.
  pngLosslessFlags = {
    oxipng = level: "-o${toString level} --strip all --alpha";
    optipng = "-o7 -quiet";
    advpng = "-z -4";
  };

  textFns = import ./text.nix {
    inherit
      pkgs
      lib
      system
      guardSize
      getName
      ;
  };

  # One shared import; the public wrapper selects `.out`, the bench/debug
  # handle (optimizeDynamicParts) returns the full internals attrset.
  dynamicOptimize = import ./dynamic.nix {
    inherit
      pkgs
      lib
      getName
      derefSymlinks
      system
      nixWasmRustPath
      dispatchWasmDir
      ;
  };

  optimizeFolderDynamic = optArgs: folderSrc: (dynamicOptimize optArgs folderSrc).out;

  optimizeDynamicParts = optArgs: folderSrc: dynamicOptimize optArgs folderSrc;

  commonArgs = {
    inherit
      pkgs
      lib
      system
      guardSize
      guardSizeTail
      ffmpegStripMetadata
      pngLosslessFlags
      getName
      packArchive
      optimizeFolderDynamic
      derefSymlinks
      ;
  }
  // textFns;

  # Shared with lib/compressRom/ via lib/mkFormatDispatch.nix.
  # listAware = false: every handler here takes a single src, not a list.
  dispatch =
    import ../mkFormatDispatch.nix
      {
        inherit lib resolveExtSorted sortDispatchKeys;
      }
      {
        handlersDir = ./handlers;
        inherit commonArgs aliases;
        listAware = false;
        excludeNames = [ "default.nix" ];
      };

  # Doom-only overlay (decorate/wav), merged in only while archive.nix's
  # pk3 recursion is active (see `doom` below). Neither doom handler
  # varies by prime, so mkDispatchMap is only ever called `false` here.
  doomDispatch =
    import ../mkFormatDispatch.nix
      {
        inherit lib resolveExtSorted sortDispatchKeys;
      }
      {
        handlersDir = ./doom;
        inherit commonArgs;
        aliases = doomAliases;
        listAware = false;
        excludeNames = [ "default.nix" ];
      };
  # Drop "_": doom's passthrough placeholder isn't a real override --
  # keeping it would clobber the normal map's own "_" fallback below.
  doomOverlay = removeAttrs (doomDispatch.mkDispatchMap false) [ "_" ];

  dispatchMapNormal = dispatch.mkDispatchMap false;
  dispatchMapPrime = dispatch.mkDispatchMap true;
  dispatchMapDoomNormal = dispatchMapNormal // doomOverlay;
  dispatchMapDoomPrime = dispatchMapPrime // doomOverlay;

  # Precompute the sort: resolveExt/dispatchExt would otherwise re-sort every call.
  dispatchMapNormalSorted = sortDispatchKeys dispatchMapNormal;
  dispatchMapPrimeSorted = sortDispatchKeys dispatchMapPrime;
  dispatchMapDoomNormalSorted = sortDispatchKeys dispatchMapDoomNormal;
  dispatchMapDoomPrimeSorted = sortDispatchKeys dispatchMapDoomPrime;

  cachedDispatchMap =
    prime: doom:
    if doom then
      (if prime then dispatchMapDoomPrime else dispatchMapDoomNormal)
    else
      (if prime then dispatchMapPrime else dispatchMapNormal);
  cachedSortedKeys =
    prime: doom:
    if doom then
      (if prime then dispatchMapDoomPrimeSorted else dispatchMapDoomNormalSorted)
    else
      (if prime then dispatchMapPrimeSorted else dispatchMapNormalSorted);

  # Flattened, wasm-consumable form of sortDispatchKeys's output -- value
  # is the extMap's own key (string), so the Nix side looks up the real
  # handler afterward. Must stay byte-for-byte faithful to
  # resolveExtSorted's exact/suffix/prefix, longest-match-wins semantics
  # (see lib/wasm/dispatch/src/lib.rs).
  dispatchEntriesFor =
    extMap:
    map (
      m:
      if lib.hasPrefix "$" m.name then
        {
          rawLen = builtins.stringLength m.name;
          kind = "exact";
          compareStr = lib.toLower (lib.removePrefix "$" m.name);
          key = m.name;
        }
      else if lib.hasSuffix "*" m.name then
        {
          rawLen = builtins.stringLength m.name;
          kind = "prefix";
          compareStr = lib.toLower (lib.removeSuffix "*" m.name);
          key = m.name;
        }
      else
        {
          rawLen = builtins.stringLength m.name;
          kind = "suffix";
          compareStr = lib.toLower m.name;
          key = m.name;
        }
    ) (lib.attrsToList (removeAttrs extMap [ "_" ]));

  # One batched wasm call resolves every file in an archive against the
  # dispatch table, instead of one resolveExtSorted call per file. Returns
  # an attrset keyed by filename (not list-in-order), so the caller never
  # needs to zip this back up against its input list. "_" fallback is
  # always plain passthrough, matching optimizeWith's own knownFile=true
  # "_" handler -- the only context this is ever called from.
  batchResolveDispatch =
    {
      prime ? false,
      doom ? false,
    }:
    names:
    let
      extMap = cachedDispatchMap prime doom;
      # deepSeq: force the wasm result into plain Nix values once, up
      # front, so later .${key} lookups don't each re-cross the FFI boundary.
      rawMatched =
        builtins.wasm
          {
            path = dispatchWasmPath;
            function = "resolve_dispatch_batch";
          }
          {
            entries = dispatchEntriesFor extMap;
            files = names;
          };
      matched = builtins.deepSeq rawMatched rawMatched;
    in
    # Not parallel-wrapped: builtins.parallel requires a list, matched is an attrset.
    lib.mapAttrs (_: key: if key == null then (src: src) else extMap.${key}) matched;

  # No real filename extension -> folder-shaped.
  isFolderShaped =
    src:
    (src ? passthru && src.passthru.isFolder or false)
    || (builtins.match ".*\\.[a-zA-Z0-9]+$" (src.name or "")) == null;

  # Key existence doesn't depend on prime, so `false` is fine here.
  hasExtension = name: (builtins.match ".*\\.[a-zA-Z0-9]+$" (baseNameOf name)) != null;
  extOf = name: "." + lib.toLower (lib.last (lib.splitString "." (baseNameOf name)));
  isUnhandledExt =
    {
      doom ? false,
    }:
    name:
    hasExtension name
    &&
      resolveExtSorted (cachedSortedKeys false doom) (cachedDispatchMap false doom) {
        name = baseNameOf name;
      } == null;

  # --- DISPATCH ENGINE ---

  # `prime`: lossy/aggressive variant where a format has one (pngquant,
  # mozjpeg, lossy cwebp). `doom`: merges in the doom/ overlay (decorate,
  # wav-as-flac) -- only set by dynamic-inner.nix while walking a
  # pk3-family archive's extracted contents.
  optimizeWith =
    {
      prime ? false,
      doom ? false,
      # Set for an already-extracted/walked file, never a directory --
      # skips the folder-shaped auto-detect below, which would misfire on
      # an extensionless lump name like "ANIMDEFS".
      knownFile ? false,
      # relpath as a plain string -- avoids forcing src's real store path
      # just to read its extension. dynamic-inner.nix only.
      knownName ? null,
      # Pre-resolved via batchResolveDispatch -- skips dispatchMap/
      # resolveExtSorted and the live changesExtension check below. No
      # rename applied: dynamic-inner.nix's copyScript places each file
      # by relpath already, not by the handler's own store-path name --
      # the served path/filename is correct. The handler chain's own
      # last-stage name (e.g. "foo-oxipng-optipng-advpng.png") does stay
      # referenced in the closure though: optimizeFolderDynamic's output
      # is recursive-mode CA (no hard-fail on a stray reference, unlike
      # packArchive's flat mode) and copyScript symlinks rather than
      # copies, so the chain's intermediate name shows up in `nh`/
      # `nix-store -q --references` diffs. Intentional -- this path is
      # never dereferenced (see archive.nix's derefSymlinks, skipped here
      # on purpose for build speed) -- not a bug to "fix" later.
      knownHandler ? null,
    }:
    src:
    if builtins.isList src then
      map (optimizeWith { inherit prime doom knownFile; }) src
    else if knownHandler != null then
      knownHandler src
    else if
      dispatch.handlers.archive.changesExtension (
        if knownName != null then { name = knownName; } else src
      )
    then
      # A real extension change can't survive the final `rename` below --
      # see archive.nix's own comment.
      dispatch.handlers.archive.process prime src
    else if !knownFile && isFolderShaped src then
      folderWalkOptimize { inherit prime; } src
    else
      let
        dispatchMap = (cachedDispatchMap prime doom) // {
          "_" = src: src;
        };
        # knownName skips forcing src's real store path just for its extension.
        handler = resolveExtSorted (cachedSortedKeys prime doom) dispatchMap (
          if knownName != null then { name = knownName; } else src
        );
      in
      handler src |> rename src;

  # For folders with no static archiveContent (e.g. wallpapers). `doom`
  # context is derived by optimizeFolderDynamic from the folder's own
  # passthru.isDoom tag -- never set for a plain folder here. A recorded
  # file list riding along on the folder (fetched zips, cruft-pruned
  # trees) enables per-archive handlerFiles filtering.
  folderWalkOptimize =
    { prime }:
    folderSrc:
    optimizeFolderDynamic {
      inherit prime;
      fileList = folderSrc.passthru.fileList or null;
    } folderSrc;

  # --- PUBLIC API ---

  optimize = optimizeWith { prime = false; };
  optimize' = optimizeWith { prime = true; };
in
{
  inherit
    guardSize
    optimize
    optimize'
    optimizeWith
    optimizeFolderDynamic
    optimizeDynamicParts
    isUnhandledExt
    extOf
    batchResolveDispatch
    ;
}
