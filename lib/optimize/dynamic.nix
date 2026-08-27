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
  # Threaded from default.nix (which threads it from its own caller): the
  # sandboxed nested-archive recursion re-evaluates this file with the
  # reconstructed inner pkgs, and touching pkgs.stdenv there would boot the
  # whole bootstrap just to read the platform string.
  system ? pkgs.stdenv.hostPlatform.system,
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
  # Eval-time file list for this archive/folder (recorded pk3/rpa listings
  # via passthru.fileList, etc.), or null for the full handler set. Passed
  # to the prep derivation as JSON; py/prune-handlers.py extracts its
  # extensions at BUILD time and drops handlers/*.nix the list can't reach,
  # so adding a NEW handler leaves every archive that can't use it
  # byte-identical all the way through prep -- no rebuild cascade.
  # Handlers with only $exact/prefix* alias keys are structural and always
  # included. Nested archives found mid-walk recurse without a list and
  # get the parent's copy as-is; a file needing an excluded handler
  # degrades to passthrough rather than failing.
  fileList ? null,
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
  #
  # Static on purpose: per-archive handler pruning (which handlers/*.nix the
  # recorded file list can reach, plus the doom/ overlay) happens at BUILD
  # time now -- py/prune-handlers.py inside optimizeLibPath below, fed the
  # raw fileList as JSON. The old eval-time version walked the list and ran
  # lib.fileset union/difference algebra over ../. per archive, which cost
  # real seconds of outer eval per game; the prep derivation is CA, so the
  # caching granularity (same list extensions => same stripped tree) is
  # unchanged.
  #
  # (Caveat inherited from the old eval-time shape: a nested pk3 inside a
  # non-doom filtered archive recurses with doom=true into a copy whose
  # doom/ was pruned by the PARENT's flag; its inner walk will fail loudly
  # rather than silently passthrough. Rare, and visible beats wrong.)
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
  # Strip comments across the entire lib fileset, run the binding
  # tree-shaker on the four trimmed files, format them, and assemble the
  # final tree -- all in ONE derivation. These steps always rebuilt
  # together anyway (each consumed the previous CA output); fusing drops
  # two full-tree copies/hashes from every cold pass.
  # Raw `derivation`, not pkgs.runCommand: nested-archive recursion
  # re-evaluates THIS file inside the inner sandbox, whose pkgs is the tool
  # overlay -- no runCommand/stdenv there (see dynamic-inner.nix).
  # nativeBuildInputs becomes an explicit PATH export instead.
  optimizeLibPath = derivation (
    {
      name = "optimize-lib";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.python3}/bin:${pkgs.nixfmt}/bin:${pkgs.coreutils}/bin
          mkdir -p "$out"
          # Verbatim base first (non-.nix assets: awk/, js/, sh/, py/), then
          # --strip-tree OVERWRITES each .nix in place with its stripped
          # version (same final state the old strip->overlay pipeline made).
          cp -r --no-preserve=mode "${rawLibSource}"/. "$out"/
          python3 ${./py/trim-lib.py} --strip-tree "${rawLibSource}" "$out"
          mkdir -p "$TMPDIR/trim"
          python3 ${./py/trim-lib.py} "$out" "$out/optimize" "$TMPDIR/trim" \
            "${lib.concatStringsSep "," trimmedFiles}"
          cp "$TMPDIR"/trim/*.nix "$out"/
          nixfmt "$out"/${lib.concatStringsSep " \"$out\"/" trimmedFiles}
          # Handler pruning LAST: --strip-tree above mirrors every *.nix from
          # the (unpruned) source tree into $out, so anything pruned earlier
          # would just be resurrected. Runs on the final assembled tree.
          # -P: without it sys.path[0] is the script's own directory -- which
          # for a store-path script IS /nix/store -- and every stdlib import
          # then enumerates the whole store looking for modules.
          python3 -P ${./py/prune-handlers.py} "$out" \
            "$fileListJSONPath" ${doomArg} ${./py/trim-lib.py}
        ''
      ];
      # Build-time handler pruning input: the raw recorded file list (see
      # py/prune-handlers.py). passAsFile keeps multi-thousand-entry lists
      # out of the .drv text itself.
      fileListJSON = builtins.toJSON fileList;
      passAsFile = [ "fileListJSON" ];
    }
    // {
      __contentAddressed = true;
      allowSubstitutes = false;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    }
  );
  # The COMMENT-STRIPPED copy from optimizeLibPath, not ./dynamic-inner.nix:
  # a doc-only edit to the real file must not re-instantiate every archive.
  innerExprPath = "${optimizeLibPath}/optimize/dynamic-inner.nix";
  primeArg = if prime then "true" else "false";
  doomArg = if doom then "true" else "false";
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
  #
  # The handlerTools block overlays every pkgs.<attr> the optimize subtree
  # can reference as a prebuilt store path, so the inner evaluator never
  # constructs a real nixpkgs package (which would boot the whole stdenv
  # bootstrap there -- see dynamic-inner.nix). Names must exist in the
  # ambient optimizePkgs -- an `inherit` here fails loudly at eval time if
  # one is renamed upstream. fonttools/glslmin are packages/
  # files (python3+fonttools env, glslmin's npm-deps FOD) promoted to real
  # packages precisely so they can ride this overlay like any other tool.
  handlerTools = {
    inherit (pkgs)
      coreutils
      bash
      gawk
      python3
      p7zip
      nodejs
      gnugrep
      advancecomp
      oxipng
      optipng
      mozjpeg
      jq
      jpegoptim
      gnused
      flac
      xdelta
      pngquant
      midicsv
      lightningcss
      libxml2
      libwebp
      icoutils
      gnupatch
      gifsicle
      gcc
      flips
      findutils
      ffmpeg-headless
      util-linux
      nixfmt
      fonttools
      glslmin
      imagemagick
      ;
  };
  toolPathsJSON = builtins.toJSON (
    {
      wadptr = "${pkgs.wadptr}";
      rpatool = "${pkgs.rpatool}";
      minijson = "${pkgs.minijson}";
      # Determinate Nix, not stock pkgs.nix -- see dynamic-inner.nix's comment.
      nix = "${pkgs.nix}";
      nixWasmRust = if nixWasmRustPath == null then null else "${nixWasmRustPath}";
      dispatchWasm = if dispatchWasmModule == null then null else "${dispatchWasmModule}";
    }
    // builtins.mapAttrs (_: p: "${p}") handlerTools
  );

  # folderSrc may symlink into another store path (lib/files.nix
  # getFiles/removeFiles) -- builtins.path in dynamic-inner.nix hashes a
  # symlink's target text, not its bytes, so per-file hashes there churn on
  # unrelated upstream changes. Dereference first (lib/files.nix's shared
  # helper, its own cached CA derivation), so both this and instantiateDrv
  # get early cutoff.
  derefFolderSrc = derefSymlinks { } folderSrc;

  # Too many concurrent nix-instantiate processes trash the disk via nix
  # sqlite write contention and can freeze the system on large folders --
  # serialize them for the duration of the inner eval.
  flockBlock = ''
    if [ -d /build-locks ]; then
      exec 9>/build-locks/dynamic-optimize.lock
      flock 9
    fi
  '';

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

        ${flockBlock}

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
{
  # The public folder-in/folder-out value -- what every caller consumes.
  out = builtins.outputOf instantiateDrv.outPath "out";

  # Internals, exposed purely for benchmarking/debugging (the .bench/
  # harness reconstructs the exact sandboxed nix-instantiate invocation
  # from these). Production callers never touch these.
  inherit
    optimizeLibPath
    instantiateDrv
    derefFolderSrc
    toolPathsJSON
    innerExprPath
    prime
    doom
    droppedExtensions
    fileList
    ;
}
