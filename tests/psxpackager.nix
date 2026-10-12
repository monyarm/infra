# PS1 disc -> EBOOT.PBP via PSXPackager, the most popular converter (MIT,
# Linux release). Uses the 240p Test Suite as the disc: a real PS1 homebrew
# image that needs no retail SYSTEM.CNF, so detection falls back to the
# filename the same way it would for any homebrew disc.
{ pkgs }:

let
  testSuite = pkgs.fetchzip {
    url = "https://github.com/filipalac/240pTestSuite-PS1/releases/download/19122020/240pTestSuitePS1.zip";
    hash = "sha256-Moi0GvN0u8+7Zu2ZWwBkC/2kZHQENhzM6b6VBRXUG6k=";
    stripRoot = false; # the release zip is a flat .bin + .cue, no wrapping dir
  };
in
pkgs.runCommand "test-psxpackager"
  {
    nativeBuildInputs = [
      (pkgs.callPackage ../packages/psxpackager.nix { })
      pkgs.python3
    ];
  }
  ''
    mkdir -p in out
    cp ${testSuite}/*.bin ${testSuite}/*.cue in/

    cd in
    psxpackager -i *.bin -o ../out

    pbp=$(ls ../out/*.pbp)

    # EBOOT.PBP container: "\0PBP" magic, version 1.0.
    head -c 4 "$pbp" | od -An -tx1 | tr -d ' \n' | grep -qx "00504250"

    # Section offset table must be non-degenerate and end at file size.
    python3 - "$pbp" <<'PY'
    import struct, sys
    data = open(sys.argv[1], 'rb').read()
    assert data[:4] == b'\x00PBP', 'bad PBP magic'
    assert data[4:8] == b'\x00\x00\x01\x00', 'unexpected PBP version'
    offsets = struct.unpack('<8I', data[8:40])
    assert offsets[0] == 0x28, f'SFO not at 0x28: {offsets[0]:#x}'
    assert offsets == tuple(sorted(offsets)), 'offsets not ascending'
    assert offsets[-1] < len(data), 'PSAR offset past EOF'
    assert data[offsets[0]:offsets[0]+4] == b'\x00PSF', 'PARAM.SFO magic'
    assert data[offsets[-1]:offsets[-1]+12] == b'PSISOIMG0000', 'DATA.PSAR magic'
    print('PBP ok: %d bytes, PSAR %d bytes' % (len(data), len(data) - offsets[-1]))
    PY

    cp "$pbp" $out
  ''
