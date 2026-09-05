{
  pkgs,
  stagedNames,
  mkPatchBundleHandler,
  ...
}:
# romconv.sh's LZMA block (bin/md/gb/gbc/gba/nds/n64/ngc/z64), dispatched
# both as a bare src (plain rom, no patches) and as a named-parts attrset
# `{ rom; patch ? null; }`, bundling the patch when present into the same
# archive.
mkPatchBundleHandler {
  outExt = "7z";
  nativeBuildInputs = [ pkgs.p7zip ];
  compressCmd = allFiles: ''
    7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=1024m -ms=on out.7z -- ${stagedNames allFiles} >/dev/null
    cp out.7z "$out"
  '';
}
