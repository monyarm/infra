# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ lib, dirs, ... }:

{
  imports =
    let
      configDir = "${dirs.modules}/config";
      configImports = lib.filter (path: path != null) (
        lib.mapAttrsToList (
          name: type:
          if type == "directory" then
            if lib.pathExists "${configDir}/${name}/default.nix" then
              "${configDir}/${name}/default.nix"
            else
              null
          else if type == "regular" && lib.hasSuffix ".nix" name && name != "lib.nix" then
            "${configDir}/${name}"
          else
            null
        ) (builtins.readDir configDir)
      );
    in
    configImports;
}
