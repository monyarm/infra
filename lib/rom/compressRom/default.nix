{
  pkgs,
  lib,
  getName,
  resolveExtSorted,
  sortDispatchKeys,
  ...
}:
let
  # ==========================================================================
  # EDIT HERE: aliases.
  # ==========================================================================

  aliases = {
    sevenzip-lzma = [
      "bin"
      "rom"
      "md"
      "gb"
      "gbc"
      "gba"
      "nds"
      "n64"
      "ngc"
      "z64"
    ];
    sevenzip-deflate = [
      "sfc"
      "smc"
      "nes"
      "fds"
      "gg"
      "sms"
      "sg"
      "mv"
    ];
    zstd = [ "vb" ];
    chd = [
      "iso"
      "img"
      "cso"
      "cue"
      "gdi"
    ];
    psp-chd = [ "psp.iso" ];
    rvz = [
      "gc.iso"
      "wii.iso"
    ];
    mame-zip = [ "zip" ];
  };

  # ==========================================================================

  fileNameOf = s: s.originalName or s.name or (builtins.baseNameOf (toString s));

  unwrapRom = x: if builtins.isAttrs x && !(lib.isDerivation x) && x ? rom then x.rom else x;

  # `cp` each of `srcs` under its real name -- for handlers staging
  # multiple related files (chd's cue/gdi+tracks, sevenzip's rom+patches).
  stageFiles =
    srcs: lib.concatMapStringsSep "\n" (s: ''cp "${s}" ${lib.escapeShellArg (fileNameOf s)}'') srcs;

  # Real names, shell-escaped -- name files explicitly instead of globbing
  # `*`, which would also sweep up nix's own build-env artifact files.
  stagedNames = srcs: lib.concatMapStringsSep " " (s: lib.escapeShellArg (fileNameOf s)) srcs;

  # "rom + optional patch/sidecar" builder, shared by sevenzip-lzma,
  # sevenzip-deflate, and zstd's patches case -- callers supply only the
  # tool invocation.
  mkPatchBundleHandler =
    {
      outExt,
      nativeBuildInputs ? [ ],
      compressCmd,
    }:
    _extra: x:
    let
      isAttrsShape = builtins.isAttrs x && !(lib.isDerivation x);
      rom = if isAttrsShape then x.rom else x;
      # Soft-patching (mGBA, RetroArch cores, ...) auto-applies a patch
      # sidecar only if its basename exactly matches the rom's -- rename each
      # patch to "<romBase>.<ext>" via originalName, which stageFiles/
      # stagedNames already prefer over the patch's own on-disk name.
      romBase =
        let
          m = builtins.match "(.*)\\.[^.]+" (fileNameOf rom);
        in
        if m == null then fileNameOf rom else lib.head m;
      patches =
        if isAttrsShape then
          let
            toPatch =
              p:
              let
                fname = fileNameOf p;
                ext =
                  let
                    m = builtins.match ".*\\.([^.]+)" fname;
                  in
                  if m == null then null else lib.head m;
              in
              if ext == null then p else p // { originalName = "${romBase}.${ext}"; };
            raw = if x.patch or null != null then x.patch else [ ];
            flat = if builtins.isList raw then raw else [ raw ];
            sidecar = lib.optional (x ? sidecar && x.sidecar != null) (
              x.sidecar // { originalName = "${romBase}.sav"; }
            );
          in
          sidecar ++ (map toPatch (lib.filter (p: p != null) flat))
        else
          [ ];
      allFiles = [ rom ] ++ patches;
    in
    pkgs.runCommand "${getName rom}.${outExt}"
      {
        inherit nativeBuildInputs;
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        ${stageFiles allFiles}
        ${compressCmd allFiles}
      '';

  commonArgs = {
    inherit
      pkgs
      lib
      getName
      fileNameOf
      stageFiles
      stagedNames
      mkPatchBundleHandler
      unwrapRom
      ;
  };

  dispatch =
    import ../../mkFormatDispatch.nix
      {
        inherit lib resolveExtSorted sortDispatchKeys;
      }
      {
        handlersDir = ./.;
        inherit commonArgs aliases;
        listAware = true;
      };

  fallback =
    _extra: x:
    let
      name =
        if builtins.isAttrs x && !(lib.isDerivation x) then
          fileNameOf (x.rom or x.cue or x.gdi or x.iso or x.img or x.cso or (lib.head (lib.attrValues x)))
        else
          fileNameOf x;
    in
    builtins.trace "compressRom: no compressor for '${name}', passing through unchanged" x;

  # Only chd/psp-chd handle a parent CHD; others would silently ignore it.
  chdFamilyExts = [ "chd" ] ++ aliases.chd ++ aliases."psp-chd";
  isChdFamily =
    x:
    let
      rom = unwrapRom x;
    in
    if builtins.isAttrs rom && !(lib.isDerivation rom) then
      rom ? cue || rom ? gdi || rom ? iso || rom ? img || rom ? cso
    else
      let
        name = lib.toLower (fileNameOf rom);
        # Longest-suffix-wins: ".gc.iso"/".wii.iso" is rvz, not chd, despite
        # also ending in plain ".iso".
        candidates = lib.sort (a: b: lib.stringLength a > lib.stringLength b) (
          chdFamilyExts ++ aliases.rvz
        );
        longestMatch = lib.findFirst (ext: lib.hasSuffix ".${ext}" name) null candidates;
      in
      builtins.elem longestMatch chdFamilyExts;

  # --- PUBLIC API ---

  # `parent`: null, or a previously-built CHD derivation. compressRom'
  # differs from compressRom only by accepting one.
  compressRom' =
    parent: x:
    if parent != null && builtins.isList x then
      throw "compressRom': parent doesn't make sense with a list (each element would share the same parent) -- call compressRom' once per element instead"
    else if parent != null && !(isChdFamily x) then
      throw "compressRom': parent is only supported for CHD-family sources (.iso/.img/.cso/.cue/.gdi/.psp.iso), got '${fileNameOf (unwrapRom x)}'"
    else
      dispatch.run {
        inherit fallback;
        extra = parent;
      } x;

  compressRom = x: compressRom' null x;
in
{
  inherit compressRom compressRom';
}
