{ pkgs, lib, ... }:
let
  dirContents = builtins.readDir ./.;
  builderNames = builtins.attrNames (
    lib.filterAttrs (
      name: type: name != "default.nix" && type == "regular" && lib.hasSuffix ".nix" name
    ) dirContents
  );
  dropSuffix = name: lib.removeSuffix ".nix" name;
in
lib.genAttrs (map dropSuffix builderNames) (name: pkgs.callPackage (./. + "/${name}.nix") { })
