#!/usr/bin/env python3
"""Losslessly recompresses an uncompressed ("FWS") SWF into a zlib-
compressed ("CWS") one -- a real, documented SWF feature the Flash Player
itself transparently decompresses, not a re-encode: the 8-byte header
(3-byte signature, version byte, 4-byte *uncompressed* total length) is
kept as-is apart from flipping the signature, and everything after it is
just zlib-deflated. Round-trip verified: zlib.decompress on the result
reproduces the original body byte-for-byte. Anything not starting with
"FWS" (already CWS/ZWS, or not a SWF at all) is passed through unchanged.
"""

import sys
import zlib

src, dest = sys.argv[1], sys.argv[2]
with open(src, "rb") as f:
    data = f.read()

if data[0:3] == b"FWS":
    header = b"CWS" + data[3:8]
    body = zlib.compress(data[8:], 9)
    out = header + body
else:
    out = data

with open(dest, "wb") as f:
    f.write(out)
