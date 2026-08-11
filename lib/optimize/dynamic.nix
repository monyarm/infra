# "Folder in, folder out": optimizes every file in a folder at *build*
# time, not eval time -- eval time doesn't scale with member count.
# Used by archive.nix (after extraction) and folderWalkOptimize.
#
# Hard-won constraint, don't regress: this returns a genuine derivation --
# nothing here builds anything itself; whatever calls optimizeFolderDynamic
# (transitively, whoever eventually runs `nix build`) is what realizes it.
#
# Mechanism: `instantiateDrv`'s build step does only `nix-instantiate` on
# dynamic-inner.nix (never a build) against the now-real folderSrc, and
# copies the resulting .drv into its own $out. Its output is declared
# outputHashMode = "text" -- the same content-addressing mode real .drv
# files use (CA, but allowed to embed store-path references as text), which
# is what lets Nix recognize a `.drv`-suffixed output as an actual
# derivation rather than an opaque blob. `builtins.outputOf` then chains
# onto that: "the eventual output of building whatever .drv instantiateDrv
# produces" -- Nix's own daemon resolves this automatically, as ordinary
# graph realization, once something actually needs it. No nested nix build/
# nix-store -r call anywhere in this file. instantiateDrv needs
# recursive-nix (nix-instantiate touches the store from inside a build);
# dynamic-derivations is what makes `builtins.outputOf` on a not-yet-built
# derivation's own output legal at all -- both already enabled ambiently via
# lib/nixSettings.nix, needed here since this chaining happens in the
# *outer* evaluation, not inside any sandbox.
#
# dynamic-inner.nix does the real per-file work (recursive folder walk,
# dispatch through optimizeWith, reassembly) in ONE nix-instantiate'd
# expression rather than one process per file -- pkgs only gets
# reconstructed once, and every file's result feeds one ordinary runCommand,
# so the resulting derivation graph is completely normal: Nix's own
# scheduler parallelizes it across builders exactly like any other build,
# no hand-rolled derivation JSON needed. `builtins.readDir`ing the folder
# inside dynamic-inner.nix is fine specifically because that expression is
# only ever evaluated once instantiateDrv's build script is actually
# running -- i.e. after the caller decided to realize this derivation, with
# folderSrc genuinely on disk by then.
#
# instantiateDrv's hard inputs are kept to exactly: optimize/ (+ the handful
# of lib/ files it reaches), the input folder, and the specific CLI tools
# handlers actually invoke (wadptr, rpatool, minijson) -- nothing else should be able
# to change its hash. Notably NOT inputs: the rest of lib/ (fetchers.nix,
# media.nix, ...), sources.nix (46000+ lines, changes constantly for
# unrelated games), or packages/'s own overlay machinery -- all of those
# would otherwise force every archive's cached instantiate step to rebuild
# on a completely unrelated edit. wadptr/rpatool/minijson are pre-built *outside*
# this derivation (via the ambient optimizePkgs overlay -- see
# hosts/modules/lib.nix) and passed in as plain store paths, so
# dynamic-inner.nix's own pkgs reconstruction never needs packages/
# default.nix (and thus never needs fetchers.nix/sources.nix) at all.
#
# misc.nix/strings.nix/constants.nix/files.nix are each much bigger than
# what optimize/ actually uses out of them (files.nix especially -- 500+
# lines of home-manager linking/secrets helpers optimize/ never touches),
# and are shared with unrelated parts of the repo, so they still change for
# reasons that have nothing to do with archive optimization. trim-lib.py
# (a plain string-scanning tree-shaker, not a real Nix parser -- see its own
# header) keeps only the bindings those four files export that optimize/'s
# handlers actually reference, transitively. It's a normal (non-sandboxed)
# derivation, so it only ever needs to re-run when one of these four files
# or optimize/ itself changes; being CA, its own early cutoff means even
# that re-run is free unless the *kept* subset's bytes actually differ.
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
  # archive.nix). Empty by default -- folderWalkOptimize keeps everything.
  droppedExtensions ? [ ],
}:
folderSrc:
let
  trimmedFiles = [
    "misc.nix"
    "strings.nix"
    "constants.nix"
    "files.nix"
  ];
  # Only what dynamic-inner.nix's own import chain actually reaches: the
  # whole optimize/ subtree, plus the specific top-level lib/ files it and
  # optimize/default.nix's own `../mkFormatDispatch` reference need.
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
        python3 ${./py/trim-lib.py} "${rawLibSource}" "${rawLibSource}/optimize" "$out" \
          "${lib.concatStringsSep "," trimmedFiles}"
        # trim-lib.py's own output isn't nixfmt-formatted (it splices raw
        # source spans together) -- format it here rather than leave it
        # readable-only by accident, and a formatting failure is also a
        # cheap syntax-validity signal on what got generated.
        nixfmt "$out"/*.nix
      '';
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
        cp ${trimmedFilesDrv}/*.nix "$out"/
      '';
  innerExprPath = ./dynamic-inner.nix;
  primeOverrideJSON = builtins.toJSON primeOverride;
  primeArg = if prime then "true" else "false";
  system = pkgs.stdenv.hostPlatform.system;
  shell = "${pkgs.bash}/bin/bash";
  droppedExtsArg = lib.concatStringsSep " " droppedExtensions;
  # Prebuilt tool store paths dynamic-inner.nix's own pkgs reconstruction
  # overlays in verbatim (see its header comment) -- one JSON blob instead of
  # a growing list of --argstr/--arg pairs that have to be added in lockstep
  # on both sides every time a new tool joins the set. Unlike --argstr,
  # builtins.toJSON can carry a real `null` for nixWasmRust, so no ""
  # sentinel is needed for the optional case either.
  toolPathsJSON = builtins.toJSON {
    wadptr = "${pkgs.wadptr}";
    rpatool = "${pkgs.rpatool}";
    minijson = "${pkgs.minijson}";
    # Determinate Nix, not stock pkgs.nix -- see dynamic-inner.nix's own
    # comment on why its pkgs reconstruction needs this overlaid too.
    nix = "${pkgs.nix}";
    nixWasmRust = if nixWasmRustPath == null then null else "${nixWasmRustPath}";
  };

  instantiateDrv = derivation {
    name = "${getName folderSrc}-optimize-instantiate.drv";
    inherit system;
    builder = shell;
    args = [
      "-c"
      ''
        set -e
        export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.nix}/bin:$PATH"
        # substituters/connect-timeout: this sandbox has no network at all,
        # so every nix invocation otherwise still probes it first.
        # parallel-eval: dynamic-inner.nix's own per-file map (thousands of
        # entries for a large archive) uses lib/misc.nix's parallel helper,
        # same as the rest of this repo already relies on elsewhere.
        export NIX_CONFIG='extra-experimental-features = nix-command ca-derivations dynamic-derivations recursive-nix pipe-operators parallel-eval
          substituters =
          connect-timeout = 1'

        drv=$(nix-instantiate --add-root "$TMPDIR/inner-drv" \
          "${innerExprPath}" \
          --argstr optimizeNixpkgsPath "${pkgs.path}" \
          --argstr optimizeLibPath "${optimizeLibPath}" \
          --argstr toolPathsJSON ${lib.escapeShellArg toolPathsJSON} \
          --argstr targetSystem "${system}" \
          --argstr folderSrc "${folderSrc}" \
          --arg prime ${primeArg} \
          --argstr primeOverrideJSON ${lib.escapeShellArg primeOverrideJSON} \
          --argstr droppedExtensions ${lib.escapeShellArg droppedExtsArg})
        # --add-root makes stdout the root symlink, not the .drv path.
        cp "$(readlink -f "$drv")" "$out"
      ''
    ];
    __contentAddressed = true;
    outputHashAlgo = "sha256";
    outputHashMode = "text";
    requiredSystemFeatures = [ "recursive-nix" ];
    # This step only ever runs nix-instantiate -- cheap evaluation, not
    # worth substitute-checking or offering to a remote builder. The real
    # per-file work (the .drv this produces) is a completely separate
    # derivation graph, dispatched normally.
    preferLocalBuild = true;
    allowSubstitutes = false;
    # Claims whole cores budget, no second instantiateDrv fits alongside it
    # -- was freezing the machine when many ran concurrently.
    cores = 0;
  };
in
builtins.outputOf instantiateDrv.outPath "out"
