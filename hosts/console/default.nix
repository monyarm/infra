# Assembles `consoleConfig.<platform>.<name>` from directories on disk.
#
# Unlike the NixOS / Home Manager / system-manager hosts next to it, a console
# config is not architecture-keyed: the public shape is
# `consoleConfig.psp.<name>`, with no system anywhere in the path.
# `sources` mirrors hosts/default.nix's signature so adding a sops-backed
# source later does not change it.
{
  inputs,
  sources ? null,
  ...
}:

let
  inherit (inputs.nixpkgs) lib;

  constants = import ../lib/constants.nix { inherit lib; };
  inherit (constants) dirs;

  pkgsGen =
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = import ./overlays.nix { inherit inputs; };
      config.allowUnfree = true;
    };

  # Phase 1 builders use a fixed platform. This is an implementation detail of
  # the derivations, not of the configuration API; see docs/research.md.
  buildPkgs = pkgsGen "x86_64-linux";

  # Only the gamebrew fetcher is used here; the rest is lazy. Site helpers are
  # null because this path never reaches them.
  fetchers = import ../../lib/fetchers.nix {
    pkgs = buildPkgs;
    inherit lib dirs;
    importSopsString = null;
    urlEncode = lib.id;
    splitFiles = _files: _drv: [ ];
    removeFiles = _paths: drv: drv;
    getFileNameFromUrl = _url: "download";
    sources = null;
  };

  consoleLib = import ../../lib/console {
    inherit lib buildPkgs;
    inherit (fetchers) fetchGameBrew;
    psxpackager = buildPkgs.callPackage ../../packages/psxpackager.nix { };
  };

  # Registry of known plugins with pinned download derivations.
  inherit (consoleLib) plugins;

  # PS1 disc(s) -> EBOOT.PBP, single- or multi-disc.
  inherit (consoleLib) mkPs1Eboot;

  modulePath = ./modules/default.nix;

  getDirNames = dirSet: lib.attrNames (lib.filterAttrs (_: type: type == "directory") dirSet);

  buildConfigurations =
    dirSet: builder:
    lib.mergeAttrsList (lib.map (name: { "${name}" = builder name; }) (getDirNames dirSet));

  # Assertions from console modules are plain booleans; a false one must fail
  # evaluation rather than silently produce an invalid generation.
  assertClean =
    name: assertions:
    let
      failed = builtins.filter (a: !a.assertion) assertions;
    in
    if failed == [ ] then
      true
    else
      throw ''
        console: '${name}' has failing assertions:
        ${lib.concatMapStringsSep "\n" (a: "  - " + a.message) failed}
      '';

  buildPspConfig =
    name:
    let
      hostDir = ./psp/${name};
      # `hostDir` is a directory, so lib.evalModules needs the module file
      # explicitly rather than relying on a default.nix that does not exist.
      evaluated = lib.evalModules {
        modules = [
          modulePath
          (hostDir + "/configuration.nix")
        ];
        # `files.nix` needs pkgs for writeTextFile; expose both names so a
        # module can use whichever convention it prefers.
        specialArgs = {
          pkgs = buildPkgs;
          inherit
            buildPkgs
            consoleLib
            dirs
            sources
            plugins
            mkPs1Eboot
            ;
        };
      };
      # Fail loudly on any module assertion before a tree is produced.
      _assertionsOk = assertClean name evaluated.config.assertions;
      entries = consoleLib.normalize evaluated.config.psp.files;
      tree = consoleLib.mkTree name entries;
    in
    {
      inherit evaluated entries;
      files = tree;
      manifest = consoleLib.mkManifest name tree entries;
      # Kept so a failed assertion is raised during evaluation.
      assertionsOk = _assertionsOk;
    };

  psp = buildConfigurations (builtins.readDir ./psp) buildPspConfig;
in
{
  inherit psp;
}
