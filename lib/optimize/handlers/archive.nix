# Generic archive handler. zip/7z extraction is uniformly `7z x` (content-
# based auto-detect, same approach gameoptimizer's src/tasks/archive.sh
# takes); rpa needs its own tool (rpatool). Repacks via lib/files.nix's
# packArchive, in the archive's own format/extension -- except pk3/ipk3,
# forced to pk7/ipk7 (7z/LZMA beats zip/deflate), which also needs
# optimizeWith's wav override and skips the size guard. `formats` below is
# the single source of truth for all of this, keyed by canonical format
# name; `extensions` and the ext->format lookup both derive from it.
{
  pkgs,
  lib,
  getName,
  guardSize,
  optimizeFolderDynamic,
  packArchive,
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
  advzipOptimize =
    zipDrv:
    pkgs.runCommand "${getName zipDrv}-advzip"
      {
        nativeBuildInputs = [ pkgs.advancecomp ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${zipDrv}" out.zip
        chmod +w out.zip
        advzip -z -4 -q out.zip || true
        cp out.zip "$out"
      '';

  commonExtractedArgs = {
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  sevenZipExtract = {
    env = commonExtractedArgs // {
      buildInputs = [ pkgs.p7zip ];
    };
    script = src: ''
      mkdir -p "$out"
      7z x -o"$out" -y "${src}" >/dev/null
    '';
  };

  rpaExtract = {
    env = commonExtractedArgs // {
      nativeBuildInputs = [ pkgs.rpatool ];
    };
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
  # identity (keep the matched extension), primeOverride to {}, guard to
  # true.
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
      outExt = ext: lib.replaceStrings [ "k3" ] [ "k7" ] ext;
      primeOverride = {
        wav = true;
      };
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
    in
    f != null && (f.outExt or (e: e)) (extOf src) != extOf src;

  process =
    prime: src:
    let
      f = formatFor src;
      ext = (f.outExt or (e: e)) (extOf src);
      extracted = pkgs.runCommand "${getName src}-extracted" f.extract.env (f.extract.script src);
      optimizedDir = optimizeFolderDynamic {
        inherit prime;
        primeOverride = f.primeOverride or { };
        droppedExtensions = droppedArchiveExtensions;
      } extracted;
      repacked = f.repack ext optimizedDir src;
    in
    if f.guard or true then guardSize repacked src else repacked;
in
{
  inherit extensions changesExtension process;
  normal = process false;
  prime = process true;
}
