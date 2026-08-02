{
  pkgs,
  lib,
  getName,
  resolveExt,
  ...
}:
let
  # ==========================================================================
  # EDIT HERE: aliases.
  # ==========================================================================

  aliases = {
    sevenzip-lzma = [ "bin" "md" "gb" "gbc" "gba" "nds" "n64" "ngc" "z64" ];
    sevenzip-deflate = [ "sfc" "smc" "nes" "fds" ];
    zstd = [ "vb" ];
    chd = [ "iso" "img" "cso" "cue" "gdi" ];
    psp-chd = [ "psp.iso" ];
    rvz = [ "gc.iso" "wii.iso" ];
  };

  # ==========================================================================

  fileNameOf = s: s.originalName or s.name or (builtins.baseNameOf (toString s));

  # Emits `cp` lines placing each of `srcs` under its real name in the
  # current directory -- shared by every handler that needs to stage
  # multiple related files together before running its tool (chd.nix's
  # cue/gdi index+tracks, the sevenzip handlers' rom+patches).
  stageFiles =
    srcs: lib.concatMapStringsSep "\n" (s: ''cp "${s}" ${lib.escapeShellArg (fileNameOf s)}'') srcs;

  # The staged (real) names of `srcs`, space-separated and shell-escaped --
  # for archiver invocations to name explicitly instead of globbing `*`,
  # which would also sweep up nix's own build-environment artifact files
  # (e.g. `env-vars`, which contains the full $PATH -- exactly the kind of
  # thing __contentAddressed's reference scanner correctly rejects) sitting
  # in the same working directory.
  stagedNames = srcs: lib.concatMapStringsSep " " (s: lib.escapeShellArg (fileNameOf s)) srcs;

  # Shared size-guard-and-retry: sums `srcs`' real sizes, runs `realCmd`
  # (expected to leave its result at $out), and if that didn't actually
  # shrink things, reruns with `fallbackCmd` instead (e.g. chd's `-c none`,
  # 7z's `-mx=0`) -- every handler needs this exact shape, only the two
  # commands differ.
  guardCompress =
    {
      srcs,
      realCmd,
      fallbackCmd,
    }:
    ''
      origSize=0
      for f in ${lib.concatMapStringsSep " " (s: lib.escapeShellArg "${s}") srcs}; do
        sz=$(stat -L -c%s "$f")
        origSize=$((origSize + sz))
      done

      ${realCmd}

      newSize=$(stat -L -c%s "$out")
      if [ "$newSize" -gt "$origSize" ]; then
        rm -f "$out"
        ${fallbackCmd}
      fi
    '';

  # Shared "rom + optional ips/bps/ups patches" builder -- sevenzip-lzma.nix,
  # sevenzip-deflate.nix, and zstd.nix's patches-present case are all just
  # this with a different outExt/compress-fallback command pair. Handles
  # normalizing bare-src-or-attrset input, staging every file under its
  # real name, and the size-guard-and-retry -- callers only ever supply
  # what actually differs: the tool invocation itself.
  mkPatchBundleHandler =
    {
      outExt,
      nativeBuildInputs ? [ ],
      # Both take the full staged file list (rom ++ patches) and must
      # leave their result at $out.
      compressCmd,
      fallbackCmd,
    }:
    extra: x:
    let
      isAttrsShape = builtins.isAttrs x && !(lib.isDerivation x);
      rom = if isAttrsShape then x.rom else x;
      patches = if isAttrsShape then lib.filter (p: p != null) [
        (x.ips or null)
        (x.bps or null)
        (x.ups or null)
      ] else [ ];
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
        ${guardCompress {
          srcs = allFiles;
          realCmd = compressCmd allFiles;
          fallbackCmd = fallbackCmd allFiles;
        }}
      '';

  commonArgs = {
    inherit
      pkgs
      lib
      getName
      fileNameOf
      stageFiles
      stagedNames
      guardCompress
      mkPatchBundleHandler
      ;
  };

  dispatch = import ../mkFormatDispatch.nix {
    inherit lib resolveExt;
  } {
    handlersDir = ./.;
    inherit commonArgs aliases;
    listAware = true;
  };

  fallback =
    extra: x:
    let
      name =
        if builtins.isAttrs x && !(lib.isDerivation x) then
          fileNameOf (x.rom or x.cue or x.gdi or x.iso or x.img or x.cso or (lib.head (lib.attrValues x)))
        else
          fileNameOf x;
    in
    builtins.trace "compressRom: no compressor for '${name}', passing through unchanged" x;

  # Only chd.nix/psp-chd.nix know what to do with a parent CHD -- everyone
  # else would silently ignore `parent`, which is more likely a caller
  # mistake than something to swallow quietly.
  chdFamilyExts = [ "chd" ] ++ aliases.chd ++ aliases."psp-chd";
  isChdFamily =
    x:
    if builtins.isAttrs x && !(lib.isDerivation x) then
      x ? cue || x ? gdi || x ? iso || x ? img || x ? cso
    else
      lib.any (ext: lib.hasSuffix ".${ext}" (lib.toLower (fileNameOf x))) chdFamilyExts;

  # --- PUBLIC API ---

  # compressRom' parent x: `parent` is `null` for "no parent", or a
  # previously-built CHD derivation directly (not an attrset -- there's
  # only ever this one optional value, unlike optimize's primeOverride).
  # `x` is a bare src, a list (mapped independently), or a named-parts
  # attrset -- see mkFormatDispatch.nix's `run` for the full dispatch
  # rules. No handler here actually has a distinct prime/normal split (all
  # are bare `extra: x: ...` functions, used for both), so compressRom'
  # differs from compressRom purely by accepting a parent -- not by trying
  # harder.
  compressRom' =
    parent: x:
    if parent != null && builtins.isList x then
      throw "compressRom': parent doesn't make sense with a list (each element would share the same parent) -- call compressRom' once per element instead"
    else if parent != null && !(isChdFamily x) then
      throw "compressRom': parent is only supported for CHD-family sources (.iso/.img/.cso/.cue/.gdi/.psp.iso), got '${fileNameOf x}'"
    else
      dispatch.run
        {
          inherit fallback;
          extra = parent;
        }
        x;

  compressRom = x: compressRom' null x;
in
{
  inherit compressRom compressRom';
}
