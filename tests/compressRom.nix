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

  # Every compression result must expose its uncompressed input as
  # passthru.raw, so a consumer can always get the original back.
  chdCue = rom.compressRom {
    cue = source "disc.cue";
    tracks = [ (source "track01.bin") ];
  };
  compressed = [
    chd
    pspChd
    rvz
    bundle
    patchedZstd
    (rom.compressRom (wrapped "romset.zip"))
    (rom.compressRom (source "solo.iso"))
    chdCue
  ];
  missingRaw = builtins.filter (d: !(d ? passthru) || !(d.passthru ? raw)) compressed;
  emptyRaw = builtins.filter (d: d.passthru.raw == [ ]) compressed;
in
assert lib.hasSuffix "game.chd" chd.name;
assert lib.hasSuffix "game.psp.chd" pspChd.name;
assert lib.hasSuffix "game.gc.rvz" rvz.name;
assert lib.hasSuffix "game.7z" bundle.name;
assert lib.hasSuffix "vb.tar.zst" patchedZstd.name;
# A cue+tracks CHD must keep the cue, not just the primary track.
assert builtins.length chdCue.passthru.raw == 2;
assert lib.hasSuffix ".cue" (toString (builtins.head chdCue.passthru.raw));
assert lib.hasSuffix ".bin" (toString (builtins.elemAt chdCue.passthru.raw 1));
assert builtins.length compressed == 8;
assert missingRaw == [ ];
assert emptyRaw == [ ];
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
