{
  pkgs,
  lib,
  getName,
  rename,
  dispatchExtSorted,
  resolveExt,
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

  aliases = {
    jpeg = [ "jpg" ];
    wad = [ "iwad" ];
    deh = [ "bex" ];
    # Plain (mymod.decorate) and "*"-suffixed (matches bare DECORATE and
    # DECORATE.ChexMonsters) -- both needed, not redundant.
    decorate =
      (lib.concatMap (p: [
        p
        "${p}*"
      ]) gzdoomLumpPrefixes)
      ++ [
        "chexmonsters"
        "doommonsters"
        "fluids"
        "green"
        "greenfluids"
        "greenmeat"
        "hereticmonsters"
        "hexenmonsters"
        "meat"
        "supergore"
        "vns"
        "dec"
        # script formats
        "acs"
        "zs"
        "zc"
      ];
    glsl = [
      "fp"
      "vp"
      "frag"
      "gl"
      "ps"
      "pso"
    ];
    obj = [ "mtl" ]; # same text format as obj
    c = [
      "h"
      "cc"
      "cpp"
      "hpp"
    ];
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
      "pal"
      "cmp"
      "ivf"
      "pcx" # rare, not worth a re-encoder
    ];
  };

  gzdoomLumpPrefixes = [
    "decorate"
    "decaldef"
    "declold"
    "sndinfo"
    "mapinfo"
    "gldefs"
    "animdefs"
    "cvarinfo"
    "language"
    "loadacs"
    "menudef"
    "gameinfo"
    "iwadinfo"
    "keyconf"
    "sbarinfo"
    "voxeldef"
    "trnslate"
    "fontdefs"
    "lockdefs"
    "modeldef"
    "textcolo"
    "sndseq"
    "terrain"
    "dec_"
    "textures"
    "zscript"
    "zmapinfo"
  ];

  # Bundled dev/build tooling, never engine content -- extractOptimizeRepack
  # only, not folderWalkOptimize (arbitrary folders keep everything).
  droppedArchiveExtensions = [
    "bat"
    "sh"
    "exe"
    "dll"
    "md"
    "gitignore"
    "gitattributes"
    "zip"
    "stackdump"
  ];

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

  optimizeFolderDynamic = import ./dynamic.nix { inherit pkgs lib getName nixWasmRustPath; };

  commonArgs = {
    inherit
      pkgs
      lib
      guardSize
      guardSizeTail
      ffmpegStripMetadata
      pngLosslessFlags
      getName
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
        handlersDir = ./.;
        excludeNames = [
          "default.nix"
          "text.nix"
          "dynamic.nix"
          "dynamic-inner.nix"
          "overlays.nix"
        ];
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
  cachedSortedKeys =
    cached dispatchMapNormalSorted dispatchMapPrimeSorted (
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
    else if !knownFile && (src.archiveContent or null) != null then
      extractOptimizeRepack {
        inherit prime primeOverride;
        outFormat = "zip";
        # Keeps the archive's own extension, unlike optimizePk3 (always .pk7/.ipk7).
        outExt = lib.last (lib.splitString "." (src.originalName or src.name));
      } src
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

  # Extracts a zip archive, optimizes each member, repacks under
  # outFormat/outExt. guard (default true): keep smaller of repacked vs
  # original. optimizePk3 passes guard = false -- LZMA beats deflate, no
  # guarantee needed.
  extractOptimizeRepack =
    {
      prime,
      primeOverride,
      outFormat,
      outExt,
      guard ? true,
    }:
    src:
    let
      fileName = src.originalName or src.name;
      # Unwraps the raw sources.nix shape when a fetcher's output skips
      # getFile (e.g. gdrive.nix). Only used for the null check below --
      # never iterated per-member (that's optimizeFolderDynamic's job now).
      rawArchiveContent = src.archiveContent or null;
      members =
        if builtins.isAttrs rawArchiveContent then
          rawArchiveContent.${fileName} or null
        else
          rawArchiveContent;
    in
    if members == null then
      builtins.trace "optimize: no known archiveContent for '${fileName}' (sources.nix not backfilled yet); passing through unoptimized" src
    else
      let
        extracted =
          pkgs.runCommand "${getName src}-extracted"
            {
              buildInputs = [ pkgs.unzip ];
              __contentAddressed = true;
              allowSubstitutes = false;
              outputHashAlgo = "sha256";
              outputHashMode = "recursive";
            }
            ''
              mkdir -p "$out"
              # -o: dupe zip entries otherwise prompt and hang the build.
              # Swallow exit 1 only for the harmless backslash-path-sep
              # warning; other exit-1s (e.g. CRC errors) are real.
              set +e
              unzipLog=$(unzip -q -o "${src}" -d "$out" 2>&1)
              status=$?
              set -e
              printf '%s\n' "$unzipLog" >&2
              if [ "$status" -ne 0 ] && { [ "$status" -ne 1 ] || printf '%s\n' "$unzipLog" | grep -qv 'appears to use backslashes as path separators'; }; then
                exit "$status"
              fi
            '';
        optimizedDir = optimizeFolderDynamic {
          inherit prime primeOverride;
          droppedExtensions = droppedArchiveExtensions;
        } extracted;
        repacked =
          optimizedDir
          |> packArchive {
            format = outFormat;
            extension = outExt;
          } (getName src);
      in
      if guard then guardSize repacked src else repacked;

  # For folders with no static archiveContent (e.g. wallpapers).
  folderWalkOptimize =
    { prime, primeOverride }:
    folderSrc: optimizeFolderDynamic { inherit prime primeOverride; } folderSrc;

  # --- PUBLIC API ---

  optimize = optimizeWith { prime = false; };
  optimize' = optimizeWith { prime = true; };

  # Doom pk3 opt-in: lossless except wav (always FLAC-under-.wav-name, see
  # wav.nix), always repacks to .pk7/.ipk7.
  optimizePk3 =
    pk3:
    let
      fileName = pk3.originalName or pk3.name;
      lowerName = lib.toLower fileName;
      outExt = if lib.hasSuffix ".ipk3" lowerName then "ipk7" else "pk7";
    in
    if !(lib.hasSuffix ".pk3" lowerName || lib.hasSuffix ".ipk3" lowerName) then
      builtins.trace "optimizePk3: '${fileName}' isn't a .pk3/.ipk3, passing through unchanged" pk3
    else
      extractOptimizeRepack {
        prime = false;
        primeOverride = {
          wav = true;
        };
        outFormat = "7z";
        guard = false;
        inherit outExt;
      } pk3;
in
{
  inherit
    guardSize
    optimize
    optimize'
    optimizePk3
    # For dynamic-inner.nix: needs primeOverride + knownFile, and the
    # build-time unhandled-extension trace.
    optimizeWith
    optimizeFolderDynamic
    isUnhandledExt
    extOf
    ;
}
