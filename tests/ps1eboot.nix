# PS1 disc(s) -> EBOOT.PBP via PSXPackager, the most popular converter (MIT,
# Linux release). Uses the 240p Test Suite as the disc: a real PS1 homebrew
# image that needs no retail SYSTEM.CNF, so detection falls back to the
# filename the same way it would for any homebrew disc. Also covers multi-disc
# titles, which PSXPackager merges into one EBOOT.PBP via an .m3u.
{ pkgs }:

let
  testSuite = pkgs.fetchzip {
    url = "https://github.com/filipalac/240pTestSuite-PS1/releases/download/19122020/240pTestSuitePS1.zip";
    hash = "sha256-Moi0GvN0u8+7Zu2ZWwBkC/2kZHQENhzM6b6VBRXUG6k=";
    stripRoot = false; # the release zip is a flat .bin + .cue, no wrapping dir
  };
  psxpackager = pkgs.callPackage ../packages/psxpackager.nix { };
  eboot = import ../lib/console/ps1eboot.nix {
    inherit (pkgs) lib;
    inherit pkgs psxpackager;
  };

  # Two distinctly-named copies of one disc, as a real multi-disc set has.
  named =
    n:
    pkgs.runCommand "ps1disc${toString n}" { } ''
      mkdir -p $out
      cp ${testSuite}/240pTestSuitePS1.bin "$out/MultiDisc - Disc ${toString n}.bin"
      sed 's/240pTestSuitePS1\.bin/MultiDisc - Disc ${toString n}.bin/' \
        ${testSuite}/240pTestSuitePS1.cue > "$out/MultiDisc - Disc ${toString n}.cue"
    '';

  single = eboot.mkPs1Eboot {
    name = "240pTestSuitePS1";
    discs = [ testSuite ];
    entries = [ "240pTestSuitePS1.cue" ];
  };
  multi = eboot.mkPs1Eboot {
    name = "MultiDisc";
    discs = [
      (named 1)
      (named 2)
    ];
    entries = [
      "MultiDisc - Disc 1.cue"
      "MultiDisc - Disc 2.cue"
    ];
  };
in
pkgs.runCommand "test-ps1eboot" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 - ${single}/EBOOT.PBP ${multi}/EBOOT.PBP <<'PY'
  import struct, sys

  def load(path, psarMagic):
      data = open(path, 'rb').read()
      assert data[:4] == b'\x00PBP', f'{path}: bad PBP magic'
      assert data[4:8] == b'\x00\x00\x01\x00', f'{path}: unexpected PBP version'
      offsets = struct.unpack('<8I', data[8:40])
      assert offsets[0] == 0x28, f'{path}: SFO not at 0x28'
      assert offsets == tuple(sorted(offsets)), f'{path}: offsets not ascending'
      assert offsets[-1] < len(data), f'{path}: PSAR offset past EOF'
      assert data[offsets[0]:offsets[0]+4] == b'\x00PSF', f'{path}: PARAM.SFO magic'
      assert data[offsets[-1]:offsets[-1]+len(psarMagic)] == psarMagic, f'{path}: DATA.PSAR magic'
      return data, offsets

  # Single-disc puts a PSISOIMG0000 straight at the PSAR offset; a multi-disc
  # PBP wraps each disc in one under an outer PSTITLEIMG000000 header.
  single, so = load(sys.argv[1], b'PSISOIMG0000')
  multi, mo = load(sys.argv[2], b'PSTITLEIMG000000')

  # One PSISOIMG0000 container per disc, and multi is a single PBP.
  assert single.count(b'PSISOIMG0000') == 1, 'single-disc PBP holds != 1 disc'
  assert multi.count(b'PSISOIMG0000') == 2, 'multi-disc PBP holds != 2 discs'

  # Both live in a single PBP -- the point of multi-disc support.
  print(f'single: {len(single)} bytes, 1 disc')
  print(f'multi:  {len(multi)} bytes, 2 discs')
  PY

  touch $out
''
