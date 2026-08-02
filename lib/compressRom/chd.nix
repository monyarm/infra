{ pkgs, lib, getName, fileNameOf, stageFiles, guardCompress, ... }:
# CHD family: dispatched both as a bare src (lone .iso/.img, or .cso --
# decompressed first -- via createdvd, no forced hunk size, matching
# chdconv.sh's original behavior) and as a named-parts attrset (`{ cue;
# bin = [...]; }` or `{ gdi; tracks = [...]; }`, via createcd, staged in a
# scratch dir under each file's *real* name so the index file's internal
# relative-path references resolve). `extra` (only ever non-null via
# compressRom') is a parent CHD, passed as -op for delta-diffed storage --
# multi-disc/regional variants sharing most of their data against a shared
# base.
extra: x:
let
  isAttrsShape = builtins.isAttrs x && !(lib.isDerivation x);

  # Normalizes both input shapes to: indexFile (the file chdman's -i points
  # at for createcd; null for the single-file createdvd path), primary (the
  # file chdman's -i points at either way), and the full set of files that
  # need staging under their real names.
  norm =
    if !isAttrsShape then
      { indexFile = null; primary = x; siblings = [ x ]; }
    else if x ? cue then
      { indexFile = x.cue; primary = x.cue; siblings = [ x.cue ] ++ x.bin; }
    else if x ? gdi then
      { indexFile = x.gdi; primary = x.gdi; siblings = [ x.gdi ] ++ x.tracks; }
    else
      let
        solePrimary = x.iso or x.img or x.cso;
      in
      { indexFile = null; primary = solePrimary; siblings = [ solePrimary ]; };

  csoFile = lib.findFirst (
    s: lib.hasSuffix ".cso" (lib.toLower (fileNameOf s))
  ) null norm.siblings;

  outName = "${getName norm.primary}.chd";
  parentArg = lib.optionalString (extra != null) ''-op "${extra}"'';

  # `codecArg` is "" for the real attempt, "-c none" for the size-guard
  # fallback. The cso decompress step (if any) happens once, before either
  # attempt, so the fallback reuses the already-decompressed iso.
  convertCmd =
    codecArg:
    if norm.indexFile != null then
      ''chdman createcd -i ${lib.escapeShellArg (fileNameOf norm.indexFile)} -o "$out" ${codecArg} ${parentArg}''
    else if csoFile != null then
      ''chdman createdvd -i decompressed.iso -o "$out" ${codecArg} ${parentArg}''
    else
      ''chdman createdvd -i ${lib.escapeShellArg (fileNameOf norm.primary)} -o "$out" ${codecArg} ${parentArg}'';
in
pkgs.runCommand outName
  {
    nativeBuildInputs = [ pkgs.mame-tools pkgs.maxcso ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    ${stageFiles norm.siblings}
    ${lib.optionalString (csoFile != null) ''
      maxcso --decompress ${lib.escapeShellArg (fileNameOf csoFile)} -o decompressed.iso
    ''}
    ${guardCompress {
      srcs = norm.siblings;
      realCmd = convertCmd "";
      fallbackCmd = convertCmd "-c none";
    }}
  ''
