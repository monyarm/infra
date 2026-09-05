{ pkgs }:

let
  inherit (pkgs) lib;
  misc = import ../lib/misc.nix { inherit pkgs lib; };
  rom = import ../lib/rom {
    inherit pkgs lib;
    inherit (misc) dispatchExt;
    getName = src: lib.sanitizeDerivationName (builtins.baseNameOf (toString src));
    inherit (misc) resolveExtSorted;
    inherit (misc) sortDispatchKeys;
  };
in
assert builtins.pathExists ../lib/rom/default.nix;
assert builtins.pathExists ../lib/rom/patchFile.nix;
assert builtins.pathExists ../lib/rom/compressRom/default.nix;
assert !(builtins.pathExists ../lib/compressRom);
assert builtins.hasAttr "patchFile" rom;
assert builtins.hasAttr "compressRom" rom;
assert builtins.hasAttr "compressRom'" rom;
pkgs.runCommand "test-rom-layout" { } "touch $out"
