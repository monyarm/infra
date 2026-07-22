#!/usr/bin/env python3
"""
wadextract.py -- native replacement for WADex, using only Python's
standard library (no Wine, no Mono).

Format reference, straight from WADex's own author (AyrA), describing
exactly what WADex reads/writes:
https://mycsharp.de/forum/threads/113775/wadex-wad-dateien-extrahieren-und-assemblieren

WAD file layout:  [ Header | Data | Index ]

Header (12 bytes):
    4s   magic          "IWAD" or "PWAD"
    i    numlumps       number of directory entries
    i    infotableofs   byte offset of the directory (index)

Index: `numlumps` entries of 16 bytes each:
    i    filepos        byte offset of this lump's data
    i    size           byte length of this lump's data
    8s   name           ASCII, space/null padded, up to 8 chars

If `size` is 0, the entry is a "virtual"/marker entry -- no data of its
own, used only to group the entries that follow it.

Confirmed real-world behavior (observed running the actual WADex.exe):
a top-level entry like "MAP34" can itself be a REAL, non-zero-size
lump whose bytes are a complete, self-contained embedded WAD file
(its own header + directory, e.g. with a lone map marker "MAP01" and
sibling lumps THINGS/LINEDEFS/SECTORS/etc inside it). Running WADex a
second time on that extracted lump is exactly how the original tooling
gets at those sibling lumps -- this script does the same thing
automatically in one call via `M`.

Usage:
    wadextract.py E <wad file> <output dir>
        Dump every real (non-marker) lump in the WAD as a loose file
        directly into <output dir>, named after the lump.

    wadextract.py I <wad file>
        Dump every directory entry (marker or not) as index / name /
        offset / size, for debugging.

    wadextract.py M <wad file> <entry name> <output dir>
        Extract everything associated with one named top-level entry,
        replicating WADex's actual behavior automatically:
          - If the entry is a zero-size marker: extract every sibling
            lump that follows it (up to the next marker) directly into
            <output dir>.
          - If the entry is a real, non-zero-size lump: write the raw
            lump itself to <output dir>/_MAP.WAD (this is the file you
            feed to a BPS patch), then check whether it's itself a
            valid embedded WAD (IWAD/PWAD magic) and, if so, recurse
            into it to find its own marker and extract its sibling
            lumps into <output dir> as well.
"""
import os
import struct
import sys

HEADER_FMT = "<4sii"
ENTRY_FMT = "<ii8s"
ENTRY_SIZE = struct.calcsize(ENTRY_FMT)


class WadEntry:
    __slots__ = ("filepos", "size", "name")

    def __init__(self, filepos, size, raw_name):
        self.filepos = filepos
        self.size = size
        self.name = raw_name.rstrip(b"\x00 ").decode("ascii", errors="replace")

    @property
    def is_marker(self):
        return self.size == 0


def parse_directory(data):
    magic, numlumps, infotableofs = struct.unpack_from(HEADER_FMT, data, 0)
    if magic not in (b"IWAD", b"PWAD"):
        return None
    entries = []
    for i in range(numlumps):
        off = infotableofs + i * ENTRY_SIZE
        filepos, size, raw_name = struct.unpack_from(ENTRY_FMT, data, off)
        entries.append(WadEntry(filepos, size, raw_name))
    return entries


def read_wad(path):
    with open(path, "rb") as f:
        data = f.read()
    entries = parse_directory(data)
    if entries is None:
        sys.exit(f"error: {path}: not a WAD file (magic={data[:4]!r})")
    return data, entries


def extract_all(wad_path, out_dir):
    data, entries = read_wad(wad_path)
    os.makedirs(out_dir, exist_ok=True)

    used_names = {}
    count = 0
    for e in entries:
        if e.is_marker:
            continue
        fname = e.name or "_"
        if fname in used_names:
            used_names[fname] += 1
            fname = f"{fname}_{used_names[fname]}"
        else:
            used_names[fname] = 0
        with open(os.path.join(out_dir, fname), "wb") as out:
            out.write(data[e.filepos:e.filepos + e.size])
        count += 1

    print(f"Extracted {count} lumps to {out_dir}", file=sys.stderr)


def info_all(wad_path):
    _, entries = read_wad(wad_path)
    print(f"{len(entries)} entries")
    print(f"{'IDX':>5}  {'MARK':4}  {'NAME':10}  {'OFFSET':>10}  {'SIZE':>10}")
    for i, e in enumerate(entries):
        mark = "YES" if e.is_marker else ""
        print(f"{i:>5}  {mark:4}  {e.name!r:10}  {e.filepos:>10}  {e.size:>10}")


def _extract_siblings(data, entries, marker_idx, out_dir):
    written = []
    i = marker_idx + 1
    while i < len(entries) and not entries[i].is_marker:
        e = entries[i]
        fname = e.name or f"_{i}"
        with open(os.path.join(out_dir, fname), "wb") as out:
            out.write(data[e.filepos:e.filepos + e.size])
        written.append(fname)
        i += 1
    return written


def extract_map(wad_path, entry_name, out_dir):
    data, entries = read_wad(wad_path)

    idx = None
    for i, e in enumerate(entries):
        if e.name == entry_name:
            idx = i
            break
    if idx is None:
        sys.exit(f"error: '{entry_name}' not found in {wad_path}")

    os.makedirs(out_dir, exist_ok=True)
    target = entries[idx]

    if target.is_marker:
        # Siblings live directly in this WAD, right after the marker.
        written = _extract_siblings(data, entries, idx, out_dir)
        if not written:
            sys.exit(f"error: marker '{entry_name}' had no lumps after it")
        print(f"Extracted from marker '{entry_name}': {', '.join(written)}", file=sys.stderr)
        return

    # Real, non-zero-size lump. Write the raw blob (this is what a BPS
    # patch is applied against), then recurse into it if it's itself a
    # valid embedded WAD.
    blob = data[target.filepos:target.filepos + target.size]
    blob_path = os.path.join(out_dir, "_MAP.WAD")
    with open(blob_path, "wb") as f:
        f.write(blob)
    print(f"Wrote raw lump '{entry_name}' ({target.size} bytes) to {blob_path}", file=sys.stderr)

    sub_entries = parse_directory(blob)
    if sub_entries is None:
        print(
            f"note: '{entry_name}' is not itself a valid embedded WAD "
            f"(magic={blob[:4]!r}) -- only _MAP.WAD was written",
            file=sys.stderr,
        )
        return

    marker_idx = None
    for i, e in enumerate(sub_entries):
        if e.is_marker:
            marker_idx = i
            break
    if marker_idx is None:
        sys.exit(f"error: no marker found inside embedded WAD for '{entry_name}'")

    written = _extract_siblings(blob, sub_entries, marker_idx, out_dir)
    if not written:
        sys.exit(f"error: embedded marker '{sub_entries[marker_idx].name}' had no lumps after it")
    print(
        f"Extracted from embedded marker '{sub_entries[marker_idx].name}': {', '.join(written)}",
        file=sys.stderr,
    )


def main():
    argv = sys.argv[1:]
    if len(argv) == 3 and argv[0] == "E":
        extract_all(argv[1], argv[2])
    elif len(argv) == 2 and argv[0] == "I":
        info_all(argv[1])
    elif len(argv) == 4 and argv[0] == "M":
        extract_map(argv[1], argv[2], argv[3])
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()