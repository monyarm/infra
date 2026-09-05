{
  pkgs,
  lib,
  getName,
  fileNameOf,
  stageFiles,
  unwrapRom,
  ...
}:
# CHD family: dispatched both as a bare src (lone .iso/.img, or .cso --
# decompressed first -- via createdvd, no forced hunk size, matching
# chdconv.sh's original behavior) and as a named-parts attrset (`{ cue;
# tracks = [...]; }` or `{ gdi; tracks = [...]; }`, via createcd, staged in a
# scratch dir under each file's *real* name so the index file's internal
# relative-path references resolve). `extra` (only ever non-null via
# compressRom') is a parent CHD, passed as -op for delta-diffed storage --
# multi-disc/regional variants sharing most of their data against a shared
# base.
extra: x:
let
  source = unwrapRom x;
  isAttrsShape = builtins.isAttrs source && !(lib.isDerivation source);

  # Normalizes both input shapes to: indexFile (the file chdman's -i points
  # at for createcd; null for the single-file createdvd path), primary (the
  # file chdman's -i points at either way), and the full set of files that
  # need staging under their real names.
  norm =
    if !isAttrsShape then
      {
        indexFile = null;
        primary = source;
        siblings = [ source ];
      }
    else if source ? cue then
      {
        indexFile = source.cue;
        primary = source.cue;
        siblings = [ source.cue ] ++ source.tracks;
      }
    else if source ? gdi then
      {
        indexFile = source.gdi;
        primary = source.gdi;
        siblings = [ source.gdi ] ++ source.tracks;
      }
    else
      let
        solePrimary = source.iso or source.img or source.cso;
      in
      {
        indexFile = null;
        primary = solePrimary;
        siblings = [ solePrimary ];
      };

  csoFile = lib.findFirst (s: lib.hasSuffix ".cso" (lib.toLower (fileNameOf s))) null norm.siblings;

  outName = "${getName norm.primary}.chd";
  parentArg = lib.optionalString (extra != null) ''-op "${extra}"'';

  # The cso decompress step happens once before chdman reuses the decompressed
  # iso.
  convertCmd =
    if norm.indexFile != null then
      ''chdman createcd -i ${lib.escapeShellArg (fileNameOf norm.indexFile)} -o "$out" ${parentArg}''
    else if csoFile != null then
      ''chdman createdvd -i decompressed.iso -o "$out" ${parentArg}''
    else
      ''chdman createdvd -i ${lib.escapeShellArg (fileNameOf norm.primary)} -o "$out" ${parentArg}'';
in
pkgs.runCommand outName
  {
    nativeBuildInputs = [
      pkgs.mame-tools
      pkgs.maxcso
    ];
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
    ${convertCmd}
  ''
