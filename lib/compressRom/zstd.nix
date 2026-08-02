{ pkgs, lib, getName, stagedNames, mkPatchBundleHandler, ... }:
# romconv.sh's .vb block, bumped from the script's default compression
# level to genuinely maximum (-19 --ultra) -- "best possible compression"
# means actually maxing it out, not what the script happened to use.
# Dispatched both as a bare src (plain rom, no patches -- stays a plain
# .vb.zst, matching today's behavior exactly) and as a named-parts attrset
# `{ rom; ips ? null; bps ? null; ups ? null; }`. zstd itself only
# compresses a single stream (no archive concept), so when there *are*
# patches, they're tarred together first via the same mkPatchBundleHandler
# every other rom-with-patches format uses -- just with tar+zstd as the
# "compress" command instead of 7z (`.vb.tar.zst`).
extra: x:
let
  isAttrsShape = builtins.isAttrs x && !(lib.isDerivation x);
  hasPatches =
    isAttrsShape && lib.any (k: (x.${k} or null) != null) [ "ips" "bps" "ups" ];
in
if !hasPatches then
  let
    rom = if isAttrsShape then x.rom else x;
  in
  pkgs.runCommand "${getName rom}.vb.zst"
    {
      nativeBuildInputs = [ pkgs.zstd ];
      __contentAddressed = true;
      allowSubstitutes = false;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    }
    ''
      zstd -19 --ultra "${rom}" -o "$out"
    ''
else
  mkPatchBundleHandler {
    outExt = "vb.tar.zst";
    nativeBuildInputs = [ pkgs.zstd pkgs.gnutar ];
    compressCmd = allFiles: ''tar cf - -- ${stagedNames allFiles} | zstd -19 --ultra -o "$out"'';
    # zstd has no true "store" mode, but a low effort level is still a
    # meaningfully different, cheaper retry in the same spirit as 7z's
    # -mx=0 -- this path only ever runs if -19/--ultra somehow didn't
    # shrink things.
    fallbackCmd = allFiles: ''tar cf - -- ${stagedNames allFiles} | zstd -1 -o "$out"'';
  } extra x
