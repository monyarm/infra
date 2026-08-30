{ pkgs }:

let
  dirContents = builtins.readDir ./.;
  testNames = builtins.attrNames (
    pkgs.lib.filterAttrs (
      name: type: name != "default.nix" && type == "regular" && pkgs.lib.hasSuffix ".nix" name
    ) dirContents
  );
  dropSuffix = name: pkgs.lib.removeSuffix ".nix" name;
in
pkgs.lib.genAttrs (map dropSuffix testNames) (name: pkgs.callPackage (./. + "/${name}.nix") { })
