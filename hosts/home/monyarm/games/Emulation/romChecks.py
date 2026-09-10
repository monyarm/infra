"""Small, dependency-free ROM plausibility checks for build-time validation."""

from __future__ import annotations

import sys
from pathlib import Path

GBA_LOGO = bytes.fromhex(
    "24ffae51699aa2213d84820a84e409ad11248b98c0c00a24" + "8b98c0c00a24" * 22
)


def record(status: str, name: str, message: str) -> None:
    print(f"{status}\t{name}\t{message.replace(chr(10), ' ')}")


def check_nes(data: bytes) -> bool:
    ok = True
    magic = data[:4] in (b"NES\x1a",)
    record(
        "PASS" if magic else "FAIL",
        "magic",
        "iNES magic" if magic else "missing iNES magic",
    )
    ok &= magic
    header = len(data) >= 16
    record(
        "PASS" if header else "FAIL",
        "header",
        "16-byte header" if header else "truncated header",
    )
    ok &= header
    if not header:
        record("FAIL", "bounds", "file is shorter than the header")
        record("FAIL", "mapper", "mapper fields unavailable")
        return bool(ok)

    trainer = 512 if data[6] & 4 else 0
    expected = 16 + trainer + data[4] * 16384 + data[5] * 8192
    bounds = expected <= len(data) and expected > 16
    record("PASS" if bounds else "FAIL", "bounds", f"declared payload {expected} bytes")
    ok &= bounds
    version = (data[7] >> 2) & 3
    nes2 = version == 2
    mapper = (data[6] >> 4) | (data[7] & 0xF0)
    submapper = 0
    if nes2:
        mapper |= (data[8] & 0x0F) << 8
        submapper = data[8] >> 4
    sane_version = version != 3
    sane_mapper = mapper <= 0xFFF and submapper <= 0xF
    sane = sane_version and sane_mapper
    record(
        "PASS" if sane else "FAIL",
        "mapper",
        f"mapper {mapper}, submapper {submapper}, NES version {version}",
    )
    return bool(ok & sane)


def snes_header(data: bytes) -> tuple[int, bytes] | None:
    for offset in (0x7FC0, 0xFFC0, 0x40FFC0, 0x7FE0, 0xFFE0):
        if offset + 0x40 <= len(data):
            header = data[offset : offset + 0x40]
            if header[0x15] & 0x01 or header[0x15] in (0x20, 0x21, 0x30, 0x31, 0x32):
                return offset, header
    return None


def check_snes(data: bytes) -> bool:
    aligned = len(data) % 1024 == 0 or len(data) % 1024 == 512
    record(
        "PASS" if aligned else "FAIL",
        "bounds",
        "ROM size is copier-aligned" if aligned else "ROM size is not aligned",
    )
    found = snes_header(data)
    record(
        "PASS" if found else "FAIL",
        "header",
        "plausible internal header" if found else "no plausible internal header",
    )
    if not found:
        record("FAIL", "vectors", "internal header unavailable")
        record("FAIL", "checksum", "internal header unavailable")
        return False
    _, header = found
    title = header[0x00:0x15].rstrip(b"\0 \xff")
    vectors = int.from_bytes(header[0x3C:0x3E], "little")
    plausible = bool(title) and vectors not in (0, 0xFFFF)
    record(
        "PASS" if plausible else "FAIL",
        "vectors",
        "title and reset vector look plausible",
    )
    checksum = int.from_bytes(header[0x1E:0x20], "little")
    complement = int.from_bytes(header[0x1C:0x1E], "little")
    matches = ((checksum ^ complement) == 0xFFFF) if checksum or complement else False
    record(
        "PASS" if matches else "WARN",
        "checksum",
        "internal checksum pair" if matches else "checksum pair is inconsistent",
    )
    return aligned and plausible


def check_gba(data: bytes) -> bool:
    bounds = len(data) >= 0xC0 and len(data) % 4 == 0
    record(
        "PASS" if bounds else "FAIL",
        "bounds",
        "aligned GBA image" if bounds else "invalid GBA size/alignment",
    )
    vector = int.from_bytes(data[:4], "little") if len(data) >= 4 else 0
    plausible = (vector & 0xFF000000) == 0xEA000000 or (
        vector & 0x0E000000
    ) == 0x0A000000
    record(
        "PASS" if plausible else "FAIL",
        "reset-vector",
        "ARM branch" if plausible else "implausible ARM reset vector",
    )
    logo = data[4:0xA0] == GBA_LOGO
    record(
        "PASS" if logo else "WARN",
        "logo",
        "Nintendo logo" if logo else "Nintendo logo differs (allowed for homebrew)",
    )
    checksum = data[0xBD] if len(data) > 0xBD else 0
    expected = (-0x19 - sum(data[0xA0:0xBD])) & 0xFF if len(data) > 0xBD else 0
    record(
        "PASS" if checksum == expected else "WARN",
        "header-checksum",
        "header checksum" if checksum == expected else "header checksum differs",
    )
    return bool(bounds and plausible)


def check_gamegear(data: bytes) -> bool:
    valid_sizes = {8192, 16384, 32768, 49152, 65536, 131072, 262144, 524288, 1048576}
    sane = len(data) in valid_sizes
    record(
        "PASS" if sane else "FAIL",
        "bounds",
        "recognized cartridge size" if sane else "unsupported cartridge size",
    )
    header_at = next(
        (
            offset
            for offset in (0x3FF0, 0x7FF0)
            if data[offset : offset + 8] == b"TMR SEGA"
        ),
        None,
    )
    if header_at is None:
        record("WARN", "header", "no Sega header (allowed)")
    else:
        record("PASS", "header", f"Sega header at 0x{header_at:x}")
    return sane


def check_genesis(data: bytes) -> bool:
    bounds = len(data) >= 0x200 and len(data) % 2 == 0
    record(
        "PASS" if bounds else "FAIL",
        "bounds",
        "aligned cartridge image" if bounds else "invalid cartridge size/alignment",
    )
    sp = int.from_bytes(data[:4], "big") if len(data) >= 4 else 0
    pc = int.from_bytes(data[4:8], "big") if len(data) >= 8 else 0
    # Genesis has a 24-bit address bus, so SP's top byte is always 0x00;
    # the byte that must be 0xFF to land in $FF0000-$FFFFFF work RAM is
    # the next one down.
    vectors = (sp & 0x00FF0000) == 0x00FF0000 and 0x200 <= pc < len(data)
    record(
        "PASS" if vectors else "FAIL",
        "vectors",
        "plausible 68000 vectors" if vectors else "implausible 68000 vectors",
    )
    record(
        "PASS" if data[0x100:0x104] == b"SEGA" else "WARN",
        "header",
        "SEGA header"
        if data[0x100:0x104] == b"SEGA"
        else "SEGA header differs (allowed)",
    )
    record("WARN", "checksum", "internal checksum is diagnostic only")
    return bool(bounds and vectors)


CHECKS = {
    "nes": check_nes,
    "snes": check_snes,
    "gba": check_gba,
    "gamegear": check_gamegear,
    "genesis": check_genesis,
}


def main(argv: list[str]) -> int:
    if len(argv) != 3 or argv[1] not in CHECKS:
        record(
            "FAIL",
            "format",
            "unknown ROM format"
            if len(argv) < 2 or argv[1] not in CHECKS
            else "expected ROM path",
        )
        return 2
    try:
        data = Path(argv[2]).read_bytes()
    except OSError as error:
        record("FAIL", "format", str(error))
        return 1
    return 0 if CHECKS[argv[1]](data) else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
