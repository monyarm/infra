{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  sources,
}:

let
  # Import our custom library and extend the passed lib
  customLib = import ../lib {
    inherit pkgs lib;
    inherit (pkgs) system;
    mkOutOfStoreSymlink = _x: { };
    config = { };
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
      inherit sources;
    }
    // customLib
  )
)
