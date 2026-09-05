{
  pkgs,
  stagedNames,
  mkPatchBundleHandler,
  ...
}:
# romconv.sh's Deflate block (sfc/smc/nes/fds), dispatched both as a bare
# src (plain rom, no patches) and as a named-parts attrset `{ rom; patch ?
# null; }`, bundling the patch when present into the same archive.
mkPatchBundleHandler {
  outExt = "zip";
  nativeBuildInputs = [ pkgs.p7zip ];
  compressCmd = allFiles: ''
    7z a -tzip -mm=Deflate -mfb=258 -mpass=15 out.zip -- ${stagedNames allFiles} >/dev/null
    cp out.zip "$out"
  '';
}
