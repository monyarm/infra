{ pkgs }:

let
  inherit (pkgs) lib;
  misc = import ../lib/misc.nix { inherit (pkgs) lib; };
  patchFile = import ../lib/rom/patchFile.nix {
    inherit pkgs lib;
    inherit (misc) dispatchExt;
  };
  source = pkgs.writeText "patch-file-source" "source\n";
  target = pkgs.writeText "patch-file-target" "target\n";
  upsTarget = source;
  fixtures =
    pkgs.runCommand "patch-file-fixtures"
      {
        nativeBuildInputs = [
          pkgs.flips
          pkgs.python3
          pkgs.xdelta
          pkgs.diffutils
        ];
      }
      ''
        mkdir "$out"
        flips --create "${source}" "${target}" "$out/game.ips"
        flips --create "${source}" "${target}" "$out/game.bps"
        python3 - "${source}" "${upsTarget}" "$out/game.ups" <<'PY'
        import struct
        import sys
        import zlib

        source = open(sys.argv[1], "rb").read()
        target = open(sys.argv[2], "rb").read()

        def encode(value):
            result = bytearray()
            while True:
                byte = value & 0x7F
                value >>= 7
                if value == 0:
                    result.append(byte | 0x80)
                    return result
                result.append(byte)
                value -= 1

        patch = bytearray(b"UPS1")
        patch += encode(len(source))
        patch += encode(len(target))
        patch += struct.pack("<II", zlib.crc32(source), zlib.crc32(target))
        patch += struct.pack("<I", zlib.crc32(patch))
        open(sys.argv[3], "wb").write(patch)
        PY
        xdelta3 -e -s "${source}" "${target}" "$out/game.xdelta"
        cp "$out/game.xdelta" "$out/game.vcdiff"
        diff -u --label source --label target "${source}" "${target}" > "$out/game.diff" || true
        cp "$out/game.diff" "$out/game.patch"
      '';
  checks =
    lib.mapAttrsToList
      (format: expected: "cmp ${expected} ${patchFile "${fixtures}/game.${format}" source}")
      {
        ips = target;
        bps = target;
        ups = upsTarget;
        xdelta = target;
        vcdiff = target;
        diff = target;
        patch = target;
      };
in
pkgs.runCommand "test-patch-file" { } ''
  ${lib.concatStringsSep "\n" checks}
  touch "$out"
''
