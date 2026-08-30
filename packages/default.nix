{
  pkgs,
  lib ? pkgs.lib,
  sources,
  # Overridable so lib/optimize/dynamic.nix's isolated inner evaluation
  # (whose store copy of packages/ doesn't have lib/ as a real sibling) can
  # supply this via a NIX_PATH-resolved value instead. Every other caller
  # keeps today's behavior unchanged.
  libPath ? ../lib,
  # lib/wasm.nix's Cargo path dependency source -- see flake.nix's
  # nix-wasm-rust input. Optional/lazy like lib/default.nix's own default:
  # nothing here forces it unless a packages/*.nix file actually calls
  # something wasm-backed (format.toKeyValues/toSexpr, wasm.crc32).
  nixWasmRustPath ? null,
  craneLib ? null,
  # niccup's system-independent `lib` output -- see flake.nix's niccup
  # input. Optional/lazy like nixWasmRustPath above.
  niccupLib ? null,
}:

let
  # Import our custom library and extend the passed lib
  customLib = import libPath {
    inherit
      pkgs
      lib
      nixWasmRustPath
      niccupLib
      ;
    system = pkgs.stdenv.hostPlatform.system;
    mkOutOfStoreSymlink = _x: { };
    config = { };
    # No packages/*.nix uses customLib's optimize/compressRom/media/files --
    # only unrelated utility functions (filterAttrs, etc.) -- so the real
    # optimize-nixpkgs pin would be pure overhead here.
    optimizePkgs = pkgs;
  };
  extendedLib = lib // customLib // { inherit customLib; };

  # Read the current directory
  dirContents = builtins.readDir ./.;

  # Filter out default.nix and keep only directories or nix files
  packageNames = builtins.attrNames (
    extendedLib.filterAttrs (
      name: type:
      name != "default.nix"
      && (type == "directory" || (type == "regular" && extendedLib.hasSuffix ".nix" name))
    ) dirContents
  );

  # Helper to remove the extension from filename if it ends with .nix
  dropSuffix =
    name: if extendedLib.hasSuffix ".nix" name then extendedLib.removeSuffix ".nix" name else name;

in
# Map package names to callPackage calls
extendedLib.genAttrs (map dropSuffix packageNames) (
  name:
  let
    # The actual path could be name or name + ".nix"
    fileName = if builtins.hasAttr (name + ".nix") dirContents then (name + ".nix") else name;
  in
  pkgs.callPackage (./. + "/${fileName}") (
    {
      lib = extendedLib;
      inherit sources craneLib;
    }
    // customLib
  )
)
