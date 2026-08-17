# "Folder in, folder out": optimizes every file in a folder at build time,
# not eval time -- eval time doesn't scale with member count. Used by
# archive.nix (after extraction) and folderWalkOptimize.
#
# This returns a genuine derivation; nothing here builds anything itself,
# whoever eventually runs `nix build` realizes it.
#
# Mechanism: instantiateDrv's build step only `nix-instantiate`s
# dynamic-inner.nix against the now-real folderSrc and copies the
# resulting .drv to $out (outputHashMode = "text", same CA mode real .drv
# files use, so Nix treats it as an actual derivation). builtins.outputOf
# then chains onto that .drv's eventual build output, resolved by Nix's
# own daemon on demand -- no nested nix build/nix-store -r call anywhere
# here. Needs recursive-nix (nix-instantiate touches the store from
# inside a build) and dynamic-derivations (legalizes outputOf on a
# not-yet-built output), both enabled via lib/nixSettings.nix.
#
# dynamic-inner.nix does all per-file work (walk, dispatch, reassembly)
# in ONE nix-instantiate'd expression instead of one process per file, so
# the resulting derivation graph stays normal and Nix's scheduler
# parallelizes it like any other build.
#
# instantiateDrv's hard inputs are kept to exactly optimize/ (+ the lib/
# files it reaches), the input folder, and wadptr/rpatool/minijson --
# NOT the rest of lib/ (fetchers.nix, sources.nix: 46000+ lines that
# change constantly for unrelated games) or packages/'s overlay
# machinery, or every archive's cached instantiate step would rebuild on
# an unrelated edit. wadptr/rpatool/minijson are pre-built outside this
# derivation via the ambient optimizePkgs overlay (hosts/modules/lib.nix)
# and passed in as plain store paths.
#
# misc.nix/strings.nix/constants.nix/files.nix are each much bigger than
# what optimize/ uses (files.nix especially: 500+ lines of home-manager
# helpers) and are shared with unrelated parts of the repo. trim-lib.py
# (string-scanning tree-shaker, not a real Nix parser -- see its own
# header) keeps only the bindings optimize/'s handlers actually reference.
#
# strippedTreeDrv also comment-strips the whole optimize/ subtree before
# it's hashed into optimizeLibPath, so a pure-comment edit anywhere under
# lib/optimize/ can't force a pointless re-instantiate of an
# already-optimized archive.
{
  pkgs,
  lib,
  getName,
  derefSymlinks,
  nixWasmRustPath ? null,
  # Already-built lib/wasm/dispatch output dir, threaded down from an outer
  # dynamic.nix invocation via dynamic-inner.nix (see optimize/default.nix).
  # When set, skips rebuilding via ../wasm.nix -- not just an optimization:
  # a nested archive's dynamic.nix runs from the sandboxed/trimmed lib copy,
  # which doesn't carry ../wasm's crate sources at all.
  dispatchWasmDir ? null,
  ...
}:
{
  prime,
  # Extensions to drop entirely (see droppedArchiveExtensions in
  # archive.nix). Empty by default -- folderWalkOptimize keeps everything.
  droppedExtensions ? [ ],
}:
folderSrc:
let
  # Set by archive.nix on a pk3-family archive's freshly-extracted contents
  # -- never set for a plain folder.
  doom = folderSrc.passthru.isDoom or false;
  trimmedFiles = [
    "misc.nix"
    "strings.nix"
    "constants.nix"
    "files.nix"
  ];
  # dynamic-inner.nix's own import chain: a nested archive found mid-walk
  # recurses back through optimizeFolderDynamic -> this same dynamic.nix
  # file (copied verbatim into optimizeLibPath/optimize/). It never reaches
  # `import ../wasm.nix` on that path -- dynamic-inner.nix always threads
  # dispatchWasmDir through (see below), so ../wasm.nix + its crate sources
  # don't need to be in this fileset at all.
  rawLibSource = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions (
      [
        ../optimize
        ../mkFormatDispatch.nix
      ]
      ++ map (f: ../. + "/${f}") trimmedFiles
    );
  };
  # Step 1: Strip comments across the entire lib fileset first
  strippedSourceDrv =
    pkgs.runCommand "optimize-lib-stripped"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p "$out"
        python3 ${./py/trim-lib.py} --strip-tree "${rawLibSource}" "$out"
      '';

  # Step 2: Run the binding tree-shaker on the already-stripped files
  trimmedFilesDrv =
    pkgs.runCommand "optimize-lib-trimmed"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.nixfmt
        ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p "$out"
        python3 ${./py/trim-lib.py} "${strippedSourceDrv}" "${strippedSourceDrv}/optimize" "$out" \
          "${lib.concatStringsSep "," trimmedFiles}"
        nixfmt "$out"/*.nix
      '';

  # Step 3: Combine stripped tree base with trimmed overrides
  optimizeLibPath =
    pkgs.runCommand "optimize-lib"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        cp -r --no-preserve=mode "${rawLibSource}" "$out"
        cp -r --no-preserve=mode "${strippedSourceDrv}"/. "$out"/
        cp ${trimmedFilesDrv}/*.nix "$out"/
      '';
  innerExprPath = ./dynamic-inner.nix;
  primeArg = if prime then "true" else "false";
  doomArg = if doom then "true" else "false";
  system = pkgs.stdenv.hostPlatform.system;
  shell = "${pkgs.bash}/bin/bash";
  droppedExtsArg = lib.concatStringsSep " " droppedExtensions;
  # Built outside the sandbox: the sandbox has no network (substituters =
  # "" below), so cargo/rustc fetching crate deps has to happen out here.
  dispatchWasmModule =
    if dispatchWasmDir != null then
      dispatchWasmDir
    else if nixWasmRustPath == null then
      null
    else
      (import ../wasm.nix { inherit pkgs lib nixWasmRustPath; }).buildWasmModule {
        name = "nix-wasm-plugin-dispatch";
        crateDir = ../wasm/dispatch;
      };
  # One JSON blob instead of a growing --argstr/--arg list that has to be
  # added in lockstep on both sides per tool. toJSON carries real `null`
  # for nixWasmRust, no "" sentinel needed.
  toolPathsJSON = builtins.toJSON {
    wadptr = "${pkgs.wadptr}";
    rpatool = "${pkgs.rpatool}";
    minijson = "${pkgs.minijson}";
    # Determinate Nix, not stock pkgs.nix -- see dynamic-inner.nix's comment.
    nix = "${pkgs.nix}";
    nixWasmRust = if nixWasmRustPath == null then null else "${nixWasmRustPath}";
    dispatchWasm = if dispatchWasmModule == null then null else "${dispatchWasmModule}";
  };

  # folderSrc may symlink into another store path (lib/files.nix
  # getFiles/removeFiles) -- builtins.path in dynamic-inner.nix hashes a
  # symlink's target text, not its bytes, so per-file hashes there churn on
  # unrelated upstream changes. Dereference first (lib/files.nix's shared
  # helper, its own cached CA derivation), so both this and instantiateDrv
  # get early cutoff.
  derefFolderSrc = derefSymlinks { } folderSrc;

  instantiateDrv = derivation {
    name = "${getName folderSrc}-optimize-instantiate.drv";
    inherit system;
    builder = shell;
    args = [
      "-c"
      ''
        set -e
        export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.nix}/bin:${pkgs.util-linux}/bin:$PATH"
        # substituters/connect-timeout: sandbox has no network, skip the probe.
        # parallel-eval: dynamic-inner.nix's per-file map uses misc.nix's parallel helper.
        # wasm-builtin: batchResolveDispatch's builtins.wasm call needs it enabled here too.
        export NIX_CONFIG='extra-experimental-features = nix-command ca-derivations dynamic-derivations recursive-nix pipe-operators parallel-eval wasm-builtin
          substituters =
          connect-timeout = 1'

        # Too many concurrent nix-instantiate can freeze the system (nix
        # sqlite db busy) -- serialize via flock.
        if [ -d /build-locks ]; then
          exec 9>/build-locks/dynamic-optimize.lock
          flock 9
        fi

        drv=$(nix-instantiate --add-root "$TMPDIR/inner-drv" \
          "${innerExprPath}" \
          --argstr optimizeNixpkgsPath "${pkgs.path}" \
          --argstr optimizeLibPath "${optimizeLibPath}" \
          --argstr toolPathsJSON ${lib.escapeShellArg toolPathsJSON} \
          --argstr targetSystem "${system}" \
          --argstr folderSrc "${derefFolderSrc}" \
          --arg prime ${primeArg} \
          --arg doom ${doomArg} \
          --argstr droppedExtensions ${lib.escapeShellArg droppedExtsArg})
        # --add-root makes stdout the root symlink, not the .drv path.
        cp "$(readlink -f "$drv")" "$out"
      ''
    ];
    __contentAddressed = true;
    outputHashAlgo = "sha256";
    outputHashMode = "text";
    requiredSystemFeatures = [ "recursive-nix" ];
    preferLocalBuild = true;
    allowSubstitutes = false;
  };
in
builtins.outputOf instantiateDrv.outPath "out"
