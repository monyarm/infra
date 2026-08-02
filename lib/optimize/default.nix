{
  pkgs,
  lib,
  listFilesRecursive,
  getFileName,
  removeExtension,
  sanitizeName,
  getName,
  rename,
  dispatchExt,
  resolveExt,
  parallel,
  parallelZipListsWith,
  splitFiles,
  packArchive,
  removeFiles,
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
    # Each gzdoomLumpPrefixes name is registered twice: plain (real
    # ".decorate"-style dot extensions on loose files, e.g. "mymod.decorate")
    # and "*"-suffixed (resolveExt's basename-PREFIX match, e.g. "decorate*"
    # also matches the bare lump "DECORATE" and the dot-suffixed lump
    # variant "DECORATE.ChexMonsters") -- these are genuinely different
    # matches, not redundant, so both forms are needed for full coverage.
    decorate = (lib.concatMap (p: [ p "${p}*" ]) gzdoomLumpPrefixes) ++ [
      "chexmonsters" "doommonsters" "fluids" "green" "greenfluids"
      "greenmeat" "hereticmonsters" "hexenmonsters" "meat" "supergore"
      "vns" "dec"
      # script formats
      "acs" "zs" "zc"
    ];
    glsl = [ "fp" "vp" "frag" "gl" "ps" "pso" ];
    obj = [ "mtl" ]; # Wavefront material files -- same plain-text numeric-field format as obj itself.
    c = [ "h" "cc" "cpp" "hpp" ];
    # bin/ir: GDCC toolchain build artifacts, passthrough only (see c.nix).
    # pk3/ipk3/pk7/ipk7 deliberately NOT listed here anymore: a pk3/ipk3
    # with a real archiveContent passthru is caught by optimizeWith's own
    # archive branch before dispatchExt ever runs; one without (not yet
    # backfilled in sources.nix) or a pk7/ipk7 (our own already-optimized
    # output, never carries archiveContent) still falls through to the
    # generic "_" fallback below either way -- same trace-passthrough
    # behavior, just via the catch-all instead of a named alias entry.
    _ = [
      "unknown" "txt" "md2" "md3" "lmp" "lump" "raw" "o" "bin" "ir" "dat" "fon2"
      # extensionless FON2 lumps, verified via magic bytes in LegendOfDoom.pk3
      "$bigfont" "$smallfnt" "$zeldfnt2"
      "$thumbs.db"
      # SPC700 dump, tracker modules, raw PLAYPAL/COLORMAP, GZDoom IVF+VP8
      # video -- all verified by magic bytes in UJJD.pk3/GoldenSouls2
      "spc" "it" "s3m" "xm" "psm" "pal" "cmp" "ivf"
      # PCX image, verified via Castlevania's *.pcx -- rare enough (<20
      # files total) that it's not worth a dedicated re-encoder yet
      "pcx"
    ]; # not optimizable or already handled elsewhere, handle through passthrough.
  };

  gzdoomLumpPrefixes = [
    "decorate" "decaldef" "declold" "sndinfo" "mapinfo" "gldefs"
    "animdefs" "cvarinfo" "language" "loadacs" "menudef" "gameinfo"
    "iwadinfo" "keyconf" "sbarinfo" "voxeldef" "trnslate" "fontdefs"
    "lockdefs"
    "modeldef" "textcolo" "sndseq" "terrain" "dec_" "textures"
    "zscript" "zmapinfo"
  ];

  # Bundled dev/build tooling and stray artifacts inside archives, never
  # engine content -- unambiguous across every real occurrence found in a
  # pk3-wide audit (e.g. "_build.bat"/"_build.sh", "7za.dll", "vnsc.exe",
  # "CREDITS.md", ".gitignore"/".gitattributes", "SurvivorSystemBACKUP.zip",
  # "mintty.exe.stackdump"). Deliberately excludes extensions that could
  # plausibly be real, unrelated content in some other mod (tmp, qc, c, h,
  # unknown).
  #
  # Scope: only ever consulted inside extractOptimizeRepack below (pk3/ipk3
  # extraction, and optimizePk3's pk7/ipk7 conversion) -- NOT applied to
  # folderWalkOptimize's plain directory walk (e.g. wallpapers), which
  # keeps every file it finds. Archives bundle third-party build tooling
  # that genuinely never belongs in the repacked output; an arbitrary
  # folder on disk has no such convention to lean on.
  droppedArchiveExtensions = [ "bat" "sh" "exe" "dll" "md" "gitignore" "gitattributes" "zip" "stackdump" ];

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
      # Not preferLocalBuild: this runs after every stage in a chain like
      # oxipng |> optipng |> advpng, and each of those stages is already
      # free to run remotely -- pinning just this trivial compare-and-pick
      # step local would drag each stage's output back to the local
      # machine and force a re-upload to a builder for the next stage,
      # every single time.
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    };

  textFns = import ./text.nix {
    inherit pkgs lib guardSize getName;
  };

  commonArgs = {
    inherit
      pkgs
      lib
      guardSize
      getName
      ;
  }
  // textFns;

  # Handler discovery/alias resolution/prime-normal dispatch is shared with
  # lib/compressRom/ via lib/mkFormatDispatch.nix -- listAware = false since
  # every file here (and text.nix, excluded below) still takes a single
  # `src`, not a srcs list. (bulk.nix no longer exists -- folder/archive
  # handling folded directly into optimizeWith below.)
  dispatch = import ../mkFormatDispatch.nix {
    inherit lib resolveExt;
  } {
    handlersDir = ./.;
    excludeNames = [ "default.nix" "text.nix" ];
    inherit commonArgs aliases;
    listAware = false;
  };

  # A folder-shaped src has no real filename extension to dispatch on --
  # same heuristic the wallpapers caller used to hand-check before calling
  # optimizeBulk instead of optimize (an explicit `passthru.isFolder`
  # marker, or "doesn't look like it has a file extension"), now built
  # directly into optimizeWith so callers don't need to check this
  # themselves.
  isFolderShaped =
    src:
    (src ? passthru && src.passthru.isFolder or false)
    || (builtins.match ".*\\.[a-zA-Z0-9]+$" (src.name or "")) == null;

  # extOf/isUnhandledExt: does dispatchExt have any entry for this name
  # (real handler or passthrough alias)? Key existence doesn't depend on
  # prime, so `false {}` is fine here regardless of the actual call's prime.
  hasExtension = name: (builtins.match ".*\\.[a-zA-Z0-9]+$" (baseNameOf name)) != null;
  extOf = name: "." + lib.toLower (lib.last (lib.splitString "." (baseNameOf name)));
  isUnhandledExt =
    name: hasExtension name && resolveExt (dispatch.mkDispatchMap false { }) { name = baseNameOf name; } == null;

  # Warns once per distinct unhandled extension in `names`, then returns
  # `x` -- extractOptimizeRepack/folderWalkOptimize call this on their full
  # member list before recursing per-file with knownFile = true, which
  # silences the "_" handler's own warning below.
  warnUnhandledOnce =
    names: x:
    let
      exts = lib.unique (map extOf (builtins.filter isUnhandledExt names));
      forced = lib.foldl' (
        acc: ext: builtins.trace ''optimize: no optimizer for extension "${ext}"'' acc
      ) null exts;
    in
    builtins.seq forced x;

  # --- DISPATCH ENGINE ---

  # `prime` (opt-in, via optimize') means the more aggressive/lossy variant
  # where a format has one (e.g. png's pngquant, jpeg's mozjpeg re-encode,
  # webp's lossy cwebp); `normal` (the plain-optimize default, prime = false)
  # always means the lossless/safe one. primeOverride forces specific
  # extensions to a fixed prime-ness regardless of the outer `prime`, e.g.
  # { wav = true; } for wav's "prime" handler (FLAC content behind the
  # original .wav name, see wav.nix) -- opt-in per call site (see
  # optimizePk3 below), empty by default so plain optimize/optimize' always
  # mean exactly what their name says, for every extension including wav.
  optimizeWith =
    {
      prime ? false,
      primeOverride ? { },
      # Set by extractOptimizeRepack/folderWalkOptimize's own recursion:
      # a single already-extracted archive member or already-walked file,
      # never a directory or a fresh fetcher output, so the archive/folder
      # auto-detection below would only be able to get it wrong -- e.g. a
      # bare extensionless lump name like "ANIMDEFS" (a completely normal
      # GZDoom lump, real pk3s ship plenty of these) matches
      # isFolderShaped's "no recognizable extension" heuristic and would
      # otherwise crash trying to IFD-walk a plain file as a directory.
      knownFile ? false,
    }:
    src:
    if builtins.isList src then
      map (optimizeWith { inherit prime primeOverride knownFile; }) src
    else if !knownFile && (src.archiveContent or null) != null then
      extractOptimizeRepack {
        inherit prime primeOverride;
        outFormat = "zip";
        # Keeps whatever extension the archive already had (.pk3 stays
        # .pk3, .ipk3 stays .ipk3, ...) -- unlike optimizePk3, which always
        # converts to .pk7/.ipk7.
        outExt = lib.last (lib.splitString "." (src.originalName or src.name));
      } src
    else if !knownFile && isFolderShaped src then
      folderWalkOptimize { inherit prime primeOverride; } src
    else
      let
        pipelineMap = dispatchExt (
          (dispatch.mkDispatchMap prime primeOverride)
          // {
            # Batch callers already warned once per extension and pass
            # knownFile = true; only a direct top-level call reaches this.
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

  # Extracts a zip-format archive (pk3/ipk3/zip/...), optimizes each kept
  # member by recursing through optimizeWith with the given prime/
  # primeOverride, and repacks under outFormat/outExt. Shared by
  # optimizeWith's own generic archive branch above (repacks to the SAME
  # extension the archive already had, following the outer call's
  # prime-ness) and optimizePk3 below (always repacks to .pk7/.ipk7, with
  # its own fixed wav override regardless of outer prime-ness).
  extractOptimizeRepack =
    {
      prime,
      primeOverride,
      outFormat,
      outExt,
      # optimizePk3's pk3->pk7 skips this -- LZMA essentially always beats
      # deflate, so it's not worth guarding.
      guard ? true,
    }:
    src:
    let
      fileName = src.originalName or src.name;
      # Usually already the specific member list -- getFile's own
      # archiveContent passthru already does the by-filename lookup
      # (folderDrv.archiveContent.${fileName}) before this ever sees it. But
      # a call site that pipes a fetcher's output straight into optimizePk3
      # with no getFile step in between (single-file pk3 downloads, e.g.
      # gdrive.nix's legendOfDoomBase) still has the raw sources.nix shape
      # attached (nested one level under the archive's own filename), so
      # unwrap that here too if we see it.
      rawArchiveContent = src.archiveContent or null;
      members =
        if builtins.isAttrs rawArchiveContent then
          rawArchiveContent.${fileName} or null
        else
          rawArchiveContent;
      isDropped = m: lib.any (ext: lib.hasSuffix ".${ext}" (lib.toLower m)) droppedArchiveExtensions;
      keptMembers = builtins.filter (m: !(isDropped m)) members;
      droppedMembers = builtins.filter isDropped members;
    in
    if members == null then
      builtins.trace "optimize: no known archiveContent for '${fileName}' (sources.nix not backfilled yet); passing through unoptimized" src
    else
      let
        extracted = pkgs.runCommand "${getName src}-extracted"
          {
            buildInputs = [ pkgs.unzip ];
            __contentAddressed = true;
            allowSubstitutes = false;
            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
          }
          ''
            mkdir -p "$out"
            # -o: some pk3s have duplicate zip entries for the same path;
            # without it unzip prompts interactively and the build hangs/fails.
            # unzip exits 1 on warnings-only conditions too, and one such
            # warning ("appears to use backslashes as path separators", on
            # Windows-authored zips) is harmless -- unzip already converts
            # them to real subdirectories correctly (verified against a real
            # LegendOfDoom.pk3 extraction). Other exit-1 warnings (e.g. CRC
            # errors) are real problems, so only swallow exit 1 when every
            # warning line it printed is that specific known-benign one.
            set +e
            unzipLog=$(unzip -q -o "${src}" -d "$out" 2>&1)
            status=$?
            set -e
            printf '%s\n' "$unzipLog" >&2
            if [ "$status" -ne 0 ] && { [ "$status" -ne 1 ] || printf '%s\n' "$unzipLog" | grep -qv 'appears to use backslashes as path separators'; }; then
              exit "$status"
            fi
          '';
        pruned = if droppedMembers == [ ] then extracted else extracted |> removeFiles droppedMembers;
        splitDrvs = pruned |> splitFiles keptMembers;
        # zipListsWith pairs each kept member's archive-relative path
        # (keptMembers) with its matching extracted derivation (splitDrvs,
        # same order, from splitFiles), producing one linkFarm entry per file.
        optimizedEntries = parallelZipListsWith (memberPath: drv: {
          name = memberPath;
          path = optimizeWith { inherit prime primeOverride; knownFile = true; } drv;
        }) keptMembers splitDrvs;
        repacked =
          pkgs.linkFarm "${getName src}-repack-src" optimizedEntries
          |> packArchive { format = outFormat; extension = outExt; } (getName src);
      in
      warnUnhandledOnce keptMembers (if guard then guardSize repacked src else repacked);

  # IFD-walks a folder (no static archiveContent -- e.g. wallpapers, an
  # already-unpacked directory), optimizing each file found by recursing
  # through optimizeWith with the given prime/primeOverride.
  folderWalkOptimize =
    { prime, primeOverride }:
    folderSrc:
    let
      allFiles = listFilesRecursive folderSrc;
      entries = parallel (map (filePath: {
        name = builtins.unsafeDiscardStringContext (
          lib.strings.removePrefix "${folderSrc}/" (toString filePath)
        );
        path =
          builtins.path {
            name = sanitizeName (getFileName filePath);
            path = filePath;
          }
          |> optimizeWith { inherit prime primeOverride; knownFile = true; };
      })) allFiles;
    in
    warnUnhandledOnce (map getFileName allFiles) (
      pkgs.linkFarm "${getName folderSrc}-optimized-dir" entries
    );

  # --- PUBLIC API ---

  # optimize (the default) is always lossless where a format has a
  # lossless/lossy choice; optimize' opts into the lossy/aggressive variant
  # instead (see the `prime` doc comment above optimizeWith).
  optimize = optimizeWith { prime = false; };
  optimize' = optimizeWith { prime = true; };

  # Doom-specific opt-in: real lossless treatment for every member except
  # wav, which gets the FLAC-content-under-.wav-name swap regardless (see
  # wav.nix) -- plain optimize/optimize' on an archive (above) follow the
  # outer call's prime-ness uniformly instead, with no such override. Also
  # unlike plain optimize on an archive (which keeps the same extension),
  # this always repacks to .pk7/.ipk7. No longer takes a sourceEntry
  # argument -- that data now flows automatically via the archiveContent
  # passthru every relevant fetcher/getFile call already attaches.
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
        primeOverride = { wav = true; };
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
    ;
}
