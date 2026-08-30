#!/usr/bin/env python3
"""Zeroes the purely-cosmetic text fields in a ProTracker-family .mod file
(the 20-byte song title, and the 22-byte name field in each of the 31
sample headers) -- never touches sample lengths/finetune/volume/loop
points, pattern data, or PCM sample data. Passes any other file through
unchanged: the offset-1080 tag check below is the same signature libmagic
uses, so a .mod-extensioned file that isn't actually a recognized
ProTracker-family module (2/4/6/8/xxCHN, M.K./M!K!/FLT4/FLT8/TDZx/etc.)
is left untouched rather than guessed at.
"""

import sys

KNOWN_TAGS = {
    b"M.K.",
    b"M!K!",
    b"M&K!",
    b"N.T.",
    b"FLT4",
    b"FLT8",
    b"2CHN",
    b"6CHN",
    b"8CHN",
    b"5CHN",
    b"7CHN",
    b"9CHN",
    b"CD81",
    b"OKTA",
    b"OCTA",
    b"TDZ1",
    b"TDZ2",
    b"TDZ3",
}


def is_known_tag(tag):
    if tag in KNOWN_TAGS:
        return True
    # NNCH / NNCN: two-digit even channel count, e.g. "16CH", "32CN"
    if len(tag) == 4 and tag[:2].isdigit() and tag[2:] in (b"CH", b"CN"):
        return int(tag[:2]) % 2 == 0
    return False


def main():
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, "rb") as f:
        data = bytearray(f.read())

    if len(data) >= 1084 and is_known_tag(bytes(data[1080:1084])):
        data[0:20] = b"\x00" * 20
        for i in range(31):
            off = 20 + i * 30
            data[off : off + 22] = b"\x00" * 22

    with open(dst, "wb") as f:
        f.write(data)


if __name__ == "__main__":
    main()
