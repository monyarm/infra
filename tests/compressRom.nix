{ pkgs }:

let
  inherit (pkgs) lib;
  misc = import ../lib/misc.nix { inherit pkgs lib; };
  rom = import ../lib/rom {
    inherit pkgs lib;
    inherit (misc) resolveExtSorted;
    inherit (misc) sortDispatchKeys;
    getName =
      src:
      let
        name = builtins.baseNameOf (toString src);
      in
      lib.removeSuffix ".rom" (lib.removeSuffix ".iso" name);
  };
  source = name: pkgs.runCommand name { } "printf '%s\\n' ${lib.escapeShellArg name} > $out";
  wrapped = name: { rom = source name; };
  chd = rom.compressRom (wrapped "game.iso");
  pspChd = rom.compressRom (wrapped "game.psp.iso");
  rvz = rom.compressRom (wrapped "game.gc.iso");
  bundle = rom.compressRom {
    rom = source "game.rom";
    patch = source "other.ips";
    sidecar = source "other.sav";
  };
  patchedZstd = rom.compressRom {
    rom = source "game.vb";
    patch = source "game.ips";
    sidecar = source "game.sav";
  };
in
assert lib.hasSuffix "game.chd" chd.name;
assert lib.hasSuffix "game.psp.chd" pspChd.name;
assert lib.hasSuffix "game.gc.rvz" rvz.name;
assert lib.hasSuffix "game.7z" bundle.name;
assert lib.hasSuffix "vb.tar.zst" patchedZstd.name;
pkgs.runCommand "test-compress-rom-wrapped"
  {
    nativeBuildInputs = [
      pkgs.p7zip
      pkgs.gnutar
      pkgs.zstd
    ];
  }
  ''
    test -e ${bundle}
    ${pkgs.p7zip}/bin/7z l ${bundle} | grep -F 'game.rom'
    ${pkgs.p7zip}/bin/7z l ${bundle} | grep -F 'game.ips'
    ${pkgs.p7zip}/bin/7z l ${bundle} | grep -F 'game.sav'
    test -e ${patchedZstd}
    ${pkgs.zstd}/bin/zstd -dc ${patchedZstd} | ${pkgs.gnutar}/bin/tar -tf - | grep -F 'game.vb'
    ${pkgs.zstd}/bin/zstd -dc ${patchedZstd} | ${pkgs.gnutar}/bin/tar -tf - | grep -F 'game.ips'
    ${pkgs.zstd}/bin/zstd -dc ${patchedZstd} | ${pkgs.gnutar}/bin/tar -tf - | grep -F 'game.sav'
    touch $out
  ''
