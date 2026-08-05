# "Folder in, folder out": optimizes every file in a folder at *build*
# time, not eval time -- eval time doesn't scale with member count.
# Used by extractOptimizeRepack (after unzip) and folderWalkOptimize.
#
# Two hard-won constraints, don't regress:
# 1. Outer wrapper must use primitive `derivation {...}`, never
#    stdenvNoCC.mkDerivation. See TODO.md "RESOLVED: dynamic-derivations
#    output resolution".
# 2. Per-file work must go through a real derivation graph (`nix
#    derivation add`, `inputs.drvs`, `nix build "$drv^out"`), not a
#    sequential loop -- graph form lets Nix parallelize across builders.
#
# Each file is `nix-store --add`ed by basename+bytes (not archive subpath)
# so an unchanged file keeps the same store path across archive updates,
# and Nix skips rebuilding it.
{
  pkgs,
  lib,
  getName,
  nixWasmRustPath ? null,
  ...
}:
{
  prime,
  primeOverride,
  # Extensions to drop entirely (see droppedArchiveExtensions in
  # default.nix). Empty by default -- folderWalkOptimize keeps everything.
  droppedExtensions ? [ ],
}:
folderSrc:
let
  optimizeLibPath = ../.;
  optimizePackagesPath = ../../packages;
  sourcesPath = ../../sources.nix;
  innerExprPath = ./dynamic-inner.nix;
  primeOverrideJSON = builtins.toJSON primeOverride;
  primeArg = if prime then "true" else "false";
  system = pkgs.stdenv.hostPlatform.system;
  shell = "${pkgs.bash}/bin/bash";
  droppedExtsArg = lib.concatStringsSep " " droppedExtensions;
  # --argstr can't carry null -- "" is the sentinel.
  nixWasmRustPathArg = if nixWasmRustPath == null then "" else toString nixWasmRustPath;
in
derivation {
  name = "${getName folderSrc}-optimized-dir";
  inherit system;
  builder = shell;
  args = [
    "-c"
    ''
      set -e
      export PATH="${pkgs.coreutils}/bin:${pkgs.nix}/bin:${pkgs.findutils}/bin:${pkgs.jq}/bin:$PATH"
      export NIX_CONFIG='extra-experimental-features = nix-command ca-derivations dynamic-derivations recursive-nix pipe-operators'

      bashPath="${pkgs.bash}"
      coreutilsPath="${pkgs.coreutils}"
      placeholder=$(nix eval --raw --expr 'builtins.placeholder "out"')

      cd "${folderSrc}"

      drvsJson='{}'
      copyScript=""
      droppedExts="${droppedExtsArg}"

      while IFS= read -r -d ''' relpath; do
        relpath="''${relpath#./}"
        lowerRelpath=$(printf '%s' "$relpath" | tr '[:upper:]' '[:lower:]')
        dropped=false
        for ext in $droppedExts; do
          case "$lowerRelpath" in
            *".$ext") dropped=true; break ;;
          esac
        done
        [ "$dropped" = true ] && continue
        srcAdded=$(nix-store --add "$relpath")
        drv=$(nix-instantiate "${innerExprPath}" \
          --argstr optimizeNixpkgsPath "${pkgs.path}" \
          --argstr optimizeLibPath "${optimizeLibPath}" \
          --argstr optimizePackagesPath "${optimizePackagesPath}" \
          --argstr sourcesPath "${sourcesPath}" \
          --argstr determinateNixPath "${pkgs.nix}" \
          --argstr nixWasmRustPath "${nixWasmRustPathArg}" \
          --argstr targetSystem "${system}" \
          --argstr src "$srcAdded" \
          --arg prime ${primeArg} \
          --argstr primeOverrideJSON ${lib.escapeShellArg primeOverrideJSON})
        ref=$(nix eval --impure --raw --expr "builtins.outputOf (builtins.storePath \"$drv\") \"out\"")
        drvsJson=$(printf '%s' "$drvsJson" | jq --arg k "$(basename "$drv")" '. + {($k): {"outputs": ["out"], "dynamicOutputs": {}}}')
        # %q-escape: relpath/ref are untrusted filenames spliced into shell code.
        safeRelpath=$(printf '%q' "$relpath")
        safeRef=$(printf '%q' "$ref")
        copyScript="$copyScript"$'\n'"$coreutilsPath/bin/mkdir -p -- \"\$($coreutilsPath/bin/dirname -- \$out/$safeRelpath)\"; $coreutilsPath/bin/cp -- $safeRef \$out/$safeRelpath;"
      done < <(find . -type f -print0)

      repackScript="set -e"$'\n'"$coreutilsPath/bin/mkdir -p \"\$out\"$copyScript"

      repackJson=$(jq -n \
        --arg builder "$bashPath/bin/bash" \
        --arg script "$repackScript" \
        --arg placeholder "$placeholder" \
        --arg bashName "$(basename "$bashPath")" \
        --arg coreutilsName "$(basename "$coreutilsPath")" \
        --argjson drvs "$drvsJson" \
        --arg system "${system}" \
        '{
          args: ["-c", $script],
          builder: $builder,
          env: { out: $placeholder },
          inputs: { drvs: $drvs, srcs: [$bashName, $coreutilsName] },
          name: "repack",
          outputs: { out: { method: "nar", hashAlgo: "sha256" } },
          system: $system,
          version: 4
        }')

      repackDrv=$(printf '%s' "$repackJson" | nix derivation add)
      repackOut=$(nix build "$repackDrv^out" --no-link --print-out-paths)
      mkdir -p "$out"
      cp -r "$repackOut"/. "$out"/
    ''
  ];
  __contentAddressed = true;
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  requiredSystemFeatures = [ "recursive-nix" ];
}
