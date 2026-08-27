# Generic archive handler. zip/7z extraction is uniformly `7z x` (content-
# based auto-detect, same approach gameoptimizer's src/tasks/archive.sh
# takes); rpa needs its own tool (rpatool). Repacks via lib/files.nix's
# packArchive, in the archive's own format/extension -- except pk3/ipk3,
# forced to pk7/ipk7 (7z/LZMA beats zip/deflate), which also tags its
# extracted contents as doom context (see `doom`/passthru.isDoom below) and
# skips the size guard. `formats` below is the single source of truth for
# all of this, keyed by canonical format name; `extensions` and the
# ext->format lookup both derive from it.
{
  pkgs,
  lib,
  system,
  getName,
  guardSize,
  optimizeFolderDynamic,
  packArchive,
  derefSymlinks,
  ...
}:
let
  # Nested fallbacks: unsafe for a raw store path (dynamic-inner.nix's
  # knownFile recursion), which has no .name. unsafeDiscardStringContext:
  # toString on a path carries store context through baseNameOf/
  # splitString, and Nix rejects that as a `${...}` attr name (used below).
  fileNameOf =
    src:
    builtins.unsafeDiscardStringContext (
      src.originalName or (src.name or (builtins.baseNameOf (toString src)))
    );
  extOf = src: lib.last (lib.splitString "." (fileNameOf src));

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

  # advzip losslessly recompresses an existing zip's DEFLATE streams with
  # more effort (zopfli) -- Linux equivalent of gameoptimizer's
  # defluff/deflopt. advancecomp is already a dependency here (png/ico).
  # Raw `derivation`, not pkgs.runCommand: the inner sandbox overlays all
  # tools as store-path STRINGS, and runCommand (-> mkDerivation -> stdenv)
  # constructs real packages, which both boots the whole stdenv bootstrap
  # in there and reads overlaid attrs like pkgs.gcc as sets. Same reasoning
  # for every other stage below and files.nix's packArchive.
  advzipOptimize =
    zipDrv:
    derivation {
      name = "${getName zipDrv}-advzip";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.advancecomp}/bin:${pkgs.coreutils}/bin
          cp "${zipDrv}" out.zip
          chmod +w out.zip
          advzip -z -4 -q out.zip || true
          cp out.zip "$out"
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };

  commonExtractedArgs = {
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  sevenZipExtract = {
    tool = pkgs.p7zip;
    script = src: ''
      mkdir -p "$out"
      7z x -o"$out" -y "${src}" >/dev/null
    '';
  };

  rpaExtract = {
    tool = pkgs.rpatool;
    script = src: ''
      mkdir -p "$out"
      rpatool -x -o "$out" "${src}"
    '';
  };

  repackVia =
    format: ext: optimizedDir: src:
    optimizedDir
    |> packArchive {
      inherit format;
      extension = ext;
    } (getName src);
  repackZip =
    ext: optimizedDir: src:
    (repackVia "zip" ext optimizedDir src) |> advzipOptimize;
  repack7z = repackVia "7z";
  repackRpa = repackVia "rpa";

  # Every field but exts/extract/repack is optional: outExt defaults to
  # identity (keep the matched extension), doom to false, guard to true.
  formats = {
    zip = {
      exts = [
        "zip"
        "jar"
        "apk"
        # EDGE's own renamed-zip container (Doom source port); SRB2Kart's
        # own renamed-zip pk3-equivalent (Doom-engine descendant).
        "epk"
        "kart"
      ];
      extract = sevenZipExtract;
      repack = repackZip;
    };
    "7z" = {
      exts = [ "7z" ];
      extract = sevenZipExtract;
      repack = repack7z;
    };
    pk3 = {
      exts = [
        "pk3"
        "ipk3"
        "pk7"
        "ipk7"
      ];
      extract = sevenZipExtract;
      repack = repack7z;
      # toLower first -- formatFor's own lookup is already
      # case-insensitive; without this, an uppercase .PK3/.IPK3 matches
      # formatFor fine but silently fails to compare as a real extension
      # change here (replaceStrings is case-sensitive), so changesExtension
      # would wrongly say "no repack needed" for it.
      outExt = ext: lib.replaceStrings [ "k3" ] [ "k7" ] (lib.toLower ext);
      doom = true;
      guard = false;
    };
    rpa = {
      exts = [ "rpa" ];
      extract = rpaExtract;
      repack = repackRpa;
    };
  };

  extensions = lib.concatLists (lib.mapAttrsToList (_: f: f.exts) formats);
  extToFormat = lib.listToAttrs (
    lib.flatten (lib.mapAttrsToList (name: f: map (ext: lib.nameValuePair ext name) f.exts) formats)
  );
  # null for a non-archive extension -- called on every src optimizeWith
  # sees. `formats.${name} or null` isn't enough: `or` doesn't catch
  # `${null}` itself, only a missing attribute.
  formatFor =
    src:
    let
      name = extToFormat.${lib.toLower (extOf src)} or null;
    in
    if name == null then null else formats.${name};

  # pk3/ipk3 is the only format with a real outExt. A genuine extension
  # change can't survive optimizeWith's final `rename` (forces every
  # handler's result back to the input's exact name -- see wav.nix's
  # intentional same-name case), so optimizeWith calls `process` directly
  # instead of going through normal dispatch+rename. Named generically,
  # not "isPk3": any future format with a real outExt needs this too.
  changesExtension =
    src:
    let
      f = formatFor src;
      ext = extOf src;
    in
    f != null && (f.outExt or (e: e)) ext != ext;

  process =
    prime: src:
    let
      f = formatFor src;
      ext = (f.outExt or (e: e)) (extOf src);
      # Recorded listing for THIS archive: a flat passthru.fileList, or --
      # for sources.* fetches (idgames/itch/gdrive/moddb/mediafire) -- the
      # fetcher-attached archiveContent map, keyed by the archive's own
      # basename by update-sources.py's content scan. No record -> null =
      # full handler set.
      fileList =
        let
          direct = src.passthru.fileList or null;
          ac = src.passthru.archiveContent or null;
          ownKey = builtins.unsafeDiscardStringContext (
            builtins.baseNameOf (toString (src.originalName or src.name or (baseNameOf (toString src))))
          );
        in
        if direct != null then
          direct
        else if ac == null then
          null
        else if builtins.isList ac then
          # Self-attached lists (e.g. doom64's generated pk3 knows its own
          # members) come pre-narrowed.
          ac
        else
          let
            # Fetcher-attached maps are keyed by inner-archive basename;
            # compare case-insensitively since sanitization may shift case.
            hit = lib.findFirst (k: lib.toLower k == lib.toLower ownKey) null (builtins.attrNames ac);
          in
          if hit == null then null else ac.${hit};
      # Raw derivation (see advzipOptimize's comment). passthru is attached
      # with `//` AFTER the derivation -- a nested attrset passed directly
      # to `derivation {}` would be coerced to an env var and error out.
      extracted =
        let
          d = derivation (
            {
              name = "${getName src}-extracted";
              inherit system;
              builder = "${pkgs.bash}/bin/bash";
              args = [
                "-c"
                (
                  ''
                    export PATH=${f.extract.tool}/bin:${pkgs.coreutils}/bin
                  ''
                  + f.extract.script src
                )
              ];
            }
            // commonExtractedArgs
          );
        in
        d // { passthru.isDoom = f.doom or false; };
      optimizedDir = optimizeFolderDynamic {
        inherit prime;
        droppedExtensions = droppedArchiveExtensions;
        inherit fileList;
      } extracted;
      # Its own cached CA step (lib/files.nix's derefSymlinks), not inlined
      # per-format inside packArchive -- unchanged optimizedDir means this
      # (and the repack below) gets early cutoff regardless of format, so
      # this isn't 7z/zip-specific anymore, just part of the pipeline.
      derefDir = derefSymlinks { name = getName src; } optimizedDir;
      repacked = f.repack ext derefDir src;
    in
    if f.guard or true then guardSize repacked src else repacked;
in
{
  inherit extensions changesExtension process;
  normal = process false;
  prime = process true;
}
