#!/usr/bin/env python3
"""Logiqx redump DAT (XML) -> JSON keyed by exact game title.

Every redump CD/DVD entry ships a .cue sidecar alongside its .bin(s) --
even single-track discs (PS2's raw dd dump is bit-identical to its lone
.bin either way). A single-bin entry (with or without a trivial .cue)
collapses to a flat {"sha1": ..., "size": N} for the whole-disc raw dump.
Genuine multi-track entries (PS1-style mixed audio/data discs) keep the
richer {"cue": {"sha1", "size"}, "tracks": [{"sha1", "size"}, ...]} shape,
"tracks" in disc-track order, since a real player needs the actual cue
content, not a synthesizable trivial one.
"""

import glob
import json
import os
import sys
import xml.etree.ElementTree as ET


def load_entry(game):
    roms = game.findall("rom")
    parsed = [
        {"name": r.get("name"), "sha1": r.get("sha1"), "size": int(r.get("size"))}
        for r in roms
    ]

    cue = next((r for r in parsed if r["name"].lower().endswith(".cue")), None)
    tracks = [r for r in parsed if r is not cue]

    if len(tracks) == 1:
        return {"sha1": tracks[0]["sha1"], "size": tracks[0]["size"]}

    entry = {"tracks": [{"sha1": t["sha1"], "size": t["size"]} for t in tracks]}
    if cue is not None:
        entry["cue"] = {"sha1": cue["sha1"], "size": cue["size"]}
    return entry


def main():
    src_dir = sys.argv[1]
    dat_files = glob.glob(os.path.join(src_dir, "*.dat"))
    if len(dat_files) != 1:
        sys.exit(f"expected exactly one .dat file in {src_dir}, found {dat_files}")

    tree = ET.parse(dat_files[0])
    result = {
        game.get("name"): load_entry(game) for game in tree.getroot().findall("game")
    }
    json.dump(result, sys.stdout)


if __name__ == "__main__":
    main()
