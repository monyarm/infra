{
  pkgs,
  lib,
  getName,
  rename,
  dispatchExtSorted,
  resolveExtSorted,
  sortDispatchKeys,
  packArchive,
  nixWasmRustPath ? null,
  ...
}:

let
  # ==========================================================================
  # EDIT HERE: aliases and prime-selection overrides.
  # ==========================================================================

  # jpeg/wad/deh/decorate/glsl/obj/c all self-register their own aliases
  # via their handler files' own `extensions = [...]`, since each list is
  # that format's own domain knowledge -- see lib/mkFormatDispatch.nix's
  # declaredAliases. Only the generic passthrough bucket lives here, since
  # it isn't owned by any single handler.
  aliases = {
    # bin/ir: GDCC build artifacts, passthrough only.
    _ = [
      "unknown"
      "txt"
      "md2"
      "md3"
      "lmp"
      "lump"
      "raw"
      "o"
      "bin"
      "ir"
      "dat"
      "fon2"
      # extensionless FON2 lumps
      "$bigfont"
      "$smallfnt"
      "$zeldfnt2"
      "$thumbs.db"
      # SPC700, tracker modules, raw PLAYPAL/COLORMAP, GZDoom IVF+VP8
      "spc"
      "it"
      "s3m"
      "xm"
      "psm"
      "mptm"
      "pal"
      "cmp"
      "ivf"
      "pcx" # rare, not worth a re-encoder
      "kvx" # Build-engine voxel, no lossless re-encoder available
      "bmp"
      "tmp"
      "op2"
      "qc" # MilkShape/Quake3 MD3 build script, never loaded by GZDoom
      "dbs" # Doom Builder's own per-map editor settings, never loaded by GZDoom
    ];
  };

  # ==========================================================================

  guardSize =
    originalDrv: src:
    derivation {
      name = "${originalDrv.name}-g";
      system = pkgs.stdenv.hostPlatform.system;
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
          exit 0; # fix for 2176?
        ''
      ];
      # Not preferLocalBuild -- keep the compare-and-pick step remote too,
      # or every chained stage's output gets dragged home and re-uploaded.
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    };

  # Per-handler guardSize: last line of a handler's script, not a wrapping
  # derivation. Handlers must use `cmd ... || rm -f candidate` (never bare
  # `|| true`) so a crash can't leave a truncated candidate for this to miss.
  guardSizeTail = candidate: src: ''
    if [ -s "${candidate}" ] && [ "$(${pkgs.coreutils}/bin/stat -L -c%s "${candidate}")" -le "$(${pkgs.coreutils}/bin/stat -L -c%s "${src}")" ]; then
      ${pkgs.coreutils}/bin/cp "${candidate}" "$out"
    else
      ${pkgs.coreutils}/bin/cp "${src}" "$out"
    fi
  '';

  # Shared by mp3/ogg/wma/wav: lossless metadata strip via ffmpeg stream
  # copy. -fflags +bitexact also drops ffmpeg's own encoder tag.
  ffmpegStripMetadata =
    ext: src:
    pkgs.runCommand "${getName src}-stripped.${ext}"
      {
        nativeBuildInputs = [ pkgs.ffmpeg-headless ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        ffmpeg -y -i "${src}" -map_metadata -1 -fflags +bitexact -c copy tmp.${ext} || rm -f tmp.${ext}
        ${guardSizeTail "tmp.${ext}" src}
      '';

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
      guardSize
      getName
      ;
  };

  optimizeFolderDynamic = import ./dynamic.nix {
    inherit
      pkgs
      lib
      getName
      nixWasmRustPath
      ;
  };

  commonArgs = {
    inherit
      pkgs
      lib
      guardSize
      guardSizeTail
      ffmpegStripMetadata
      pngLosslessFlags
      getName
      packArchive
      optimizeFolderDynamic
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
      };

  # Precompute once; primeOverride is {} for every call except
  # optimizePk3's wav override.
  dispatchMapNormal = dispatch.mkDispatchMap false { };
  dispatchMapPrime = dispatch.mkDispatchMap true { };

  # Precompute the sort too -- resolveExt/dispatchExt re-sort every call
  # otherwise (confirmed via trace-function-calls).
  dispatchMapNormalSorted = sortDispatchKeys dispatchMapNormal;
  dispatchMapPrimeSorted = sortDispatchKeys dispatchMapPrime;

  cached =
    normalV: primeV: computeFn: prime: primeOverride:
    if primeOverride == { } then (if prime then primeV else normalV) else computeFn prime primeOverride;
  cachedDispatchMap = cached dispatchMapNormal dispatchMapPrime dispatch.mkDispatchMap;
  cachedSortedKeys = cached dispatchMapNormalSorted dispatchMapPrimeSorted (
    prime: primeOverride: sortDispatchKeys (dispatch.mkDispatchMap prime primeOverride)
  );

  # No real filename extension -> folder-shaped.
  isFolderShaped =
    src:
    (src ? passthru && src.passthru.isFolder or false)
    || (builtins.match ".*\\.[a-zA-Z0-9]+$" (src.name or "")) == null;

  # Key existence doesn't depend on prime, so `false {}` is fine here.
  hasExtension = name: (builtins.match ".*\\.[a-zA-Z0-9]+$" (baseNameOf name)) != null;
  extOf = name: "." + lib.toLower (lib.last (lib.splitString "." (baseNameOf name)));
  isUnhandledExt =
    name:
    hasExtension name
    && resolveExtSorted dispatchMapNormalSorted dispatchMapNormal { name = baseNameOf name; } == null;

  # --- DISPATCH ENGINE ---

  # `prime`: lossy/aggressive variant where a format has one (pngquant,
  # mozjpeg, lossy cwebp). primeOverride pins specific extensions
  # regardless of outer `prime`, e.g. { wav = true; } (see wav.nix).
  optimizeWith =
    {
      prime ? false,
      primeOverride ? { },
      # Set for an already-extracted/walked file, never a directory --
      # skips the folder-shaped auto-detect below, which would misfire on
      # an extensionless lump name like "ANIMDEFS".
      knownFile ? false,
    }:
    src:
    if builtins.isList src then
      map (optimizeWith { inherit prime primeOverride knownFile; }) src
    else if dispatch.handlers.archive.changesExtension src then
      # A real extension change can't survive the final `rename` below --
      # see archive.nix's own comment.
      dispatch.handlers.archive.process prime src
    else if !knownFile && isFolderShaped src then
      folderWalkOptimize { inherit prime primeOverride; } src
    else
      let
        pipelineMap = dispatchExtSorted (cachedSortedKeys prime primeOverride) (
          (cachedDispatchMap prime primeOverride)
          // {
            # Only a direct call reaches this; batch callers pass knownFile = true.
            "_" =
              src:
              if knownFile then
                src
              else
                let
                  fileName = src.name or (builtins.baseNameOf (toString src));
                in
                if hasExtension fileName then
                  builtins.trace ''optimize: no optimizer for extension "${extOf fileName}"'' src
                else
                  src;
          }
        );
      in
      src |> pipelineMap |> rename src;

  # For folders with no static archiveContent (e.g. wallpapers).
  folderWalkOptimize =
    { prime, primeOverride }:
    folderSrc: optimizeFolderDynamic { inherit prime primeOverride; } folderSrc;

  # --- PUBLIC API ---

  optimize = optimizeWith { prime = false; };
  optimize' = optimizeWith { prime = true; };
in
{
  inherit
    guardSize
    optimize
    optimize'
    # For dynamic-inner.nix: needs primeOverride + knownFile, and the
    # build-time unhandled-extension trace.
    optimizeWith
    optimizeFolderDynamic
    isUnhandledExt
    extOf
    ;
}
