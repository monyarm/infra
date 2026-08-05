{
  pkgs,
  stagedNames,
  mkPatchBundleHandler,
  ...
}:
# romconv.sh's Deflate block (sfc/smc/nes/fds), dispatched both as a bare
# src (plain rom, no patches) and as a named-parts attrset `{ rom; ips ?
# null; bps ? null; ups ? null; }`, bundling whichever patches are present
# into the same archive. Falls back to store-only (-mx=0) in the rare case
# max compression doesn't shrink things.
mkPatchBundleHandler {
  outExt = "zip";
  nativeBuildInputs = [ pkgs.p7zip ];
  compressCmd = allFiles: ''
    7z a -tzip -mm=Deflate -mfb=258 -mpass=15 out.zip -- ${stagedNames allFiles} >/dev/null
    cp out.zip "$out"
  '';
  fallbackCmd = allFiles: ''
    rm -f out.zip
    7z a -tzip -mx=0 out.zip -- ${stagedNames allFiles} >/dev/null
    cp out.zip "$out"
  '';
}
