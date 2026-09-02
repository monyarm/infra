#!/usr/bin/env python3
"""Extract maps from a set of standalone Doom II PWADs into a shared
maps/-pool pk3 tree, for feeding into MOShuffle alongside doom_fusion.ipk3.

Two kinds of manifest `sources` entries:

  - A plain string path: a "simple" source -- one self-contained wad with
    its own maps AND its own texture/flat/patch/sprite/sound/music lumps
    (tntr.wad, freedoom1.wad, etc.). Name and filename-lump prefix are both
    derived from the wad's own filename -- adding one is just adding its
    path to the list.

  - An object: a "composite" source, for a mod whose maps and resources
    live in separate files (e.g. a pk3 bundling `sam01.wad` -- map data
    only -- alongside a separate `RetroEncounter-Resources.wad` supplying
    the sprites/sounds/textures/DECORATE those maps' custom actors need).
    Shape:
      {
        "name": "sam01",
        "container": "<path to the pk3/zip everything below is read from>",
        "maps": ["sam01.wad", ...],             -- nested wads, map data only
        "resourceWads": ["Resources.wad", ...]  -- nested wads: assets +
                                                    any script lumps they own
      }
    Everything else about a composite source is auto-discovered, not
    manifest config:
      - script lumps: GZDoom's "cumulative" lump types (DECORATE/SNDINFO/
        ANIMDEFS/GLDEFS/SNDSEQ/MODELDEF -- safe to stack across pk3s, unlike
        MAPINFO/SBARINFO/KEYCONF, which are NOT cumulative and would
        clobber WadFusion's own global episode/status-bar/keybind setup if
        copied wholesale) are found in each resourceWad's catch-all `.data`
        group, then DECORATE's own `#include` lines are followed
        transitively to pick up its fragment files (DEC_ENEM, GIBACTOR,
        etc.) -- whatever the actual set is, not a hardcoded list.
      - loose files/directories: anything at the top level of `container`
        that isn't one of the `maps`/`resourceWads` members gets copied
        through as-is (files appended if a same-named file already exists
        from an earlier source; directories copied wholesale -- this is
        how 3D model/MODELDEF replacements tag along). Over-including a
        stray readme costs nothing: GZDoom ignores unrecognized top-level
        pk3 content.
    ponytail: auto-discovered script lumps/loose entries are copied under
    their original names, unnamespaced -- correct today (one composite
    source), but a second composite source reusing one of the same lump/
    directory name would collide silently. Revisit (per-source
    subdirectories, or rewriting #include lines) if that happens.

Per source (both kinds):
  - every map is extracted as maps/<PREFIX><originalname>.wad, unmodified
    geometry, no map exclusion (Hexen-format cross-map specials reference
    their target by number, not name -- see the levelnum note below;
    compiled ACS is included as-is, it rarely embeds a map name literally).
  - if the source has its own embedded MAPINFO lump (common in real
    community megawads -- e.g. TNTR ships one), its per-map Music/Sky1/Par/
    title fields are parsed and re-emitted for the renamed map -- not
    Next/SecretNext (would reference the old unprefixed name) or Cluster
    (would tie the map into WadFusion's own episode grouping). Old-style
    flat MAPINFO only (`map MAP01 "Title"` + bare keyword lines, no
    braces); the newer curly-brace format is detected and skipped rather
    than mis-parsed. GZDoom's MAPINFO loading is cumulative across every
    loaded file (confirmed against the ZDoom wiki), and we never emit a
    `GameInfo` block, so this merges with WadFusion's own automatically --
    no explicit splice needed.
  - Hexen-format maps (detected the same way omg itself does: presence of
    a BEHAVIOR lump) get a generated MAPINFO `levelnum` matching their
    original numeric suffix, so number-based cross-map specials/ACS still
    resolve correctly against the renamed map.
  - texture/flat names are dead-stripped to only what that source's own
    maps actually reference (transitively, through TEXTURE1's own patch
    lists for textures), before being checked for collisions.
  - collisions against already-claimed names (the base IWAD's own set,
    plus every earlier-processed source) are DROPPED by default (the
    existing claimant wins, source's map keeps referencing that name) --
    unless the source's derived name is listed in the manifest's
    `renameAssets` (Freedoom-shaped: an IWAD replacement, not an ordinary
    PWAD), in which case the colliding name is renamed with this source's
    own prefix and every one of that source's own maps is rewritten to
    match. Sprites/sounds/music aren't dead-stripped (no thing/type/
    DECORATE cross-reference available from raw map data), just carried
    through under the same collision policy as everything else.
"""

import json
import os
import re
import shutil
import sys
import tempfile
import zipfile

# Nix store file outputs (as opposed to directory outputs) put the store
# hash directly in the filename ("<32-char-hash>-TNTR.wad"), not a parent
# directory -- strip it before deriving a source's name/prefix, or every
# derivation would get a prefix based on essentially-random hash characters.
_NIX_HASH_PREFIX = re.compile(r"^[0-9a-z]{32}-")

NONE_TEX = "-"  # Doom's "no texture here" placeholder; never a real asset name.

# WadFusion v1.6.1's own WAD_MAP_PREFIXES (TN_/PL_/NV_/LR_/DM_/ML_) -- never
# auto-assign one of these to a map-pool source.
RESERVED_PREFIXES = {"TN", "PL", "NV", "LR", "DM", "ML"}

# GZDoom lump types that are "cumulative" (safe to stack multiple copies of,
# across pk3s) -- MAPINFO/SBARINFO/KEYCONF/GAMEINFO are deliberately not on
# this list: those are singleton/last-wins types that would clobber
# WadFusion's own global setup if a resource wad's copy got included.
SAFE_SCRIPT_LUMPS = {"DECORATE", "SNDINFO", "ANIMDEFS", "GLDEFS", "SNDSEQ", "MODELDEF"}
_INCLUDE_RE = re.compile(r'#include\s+"?([A-Za-z0-9_]+)"?', re.IGNORECASE)


def load_omg(omg_path):
    sys.path.insert(0, omg_path)
    import omg
    from omg.txdef import Textures

    return omg, Textures


def source_name(path):
    base = _NIX_HASH_PREFIX.sub("", os.path.basename(path))
    return os.path.splitext(base)[0]


def derive_prefix(name, used):
    """A unique 2-letter+underscore prefix for this source, derived from its
    name. Tries name[0:2], then name[0]+name[i] for later letters, then
    adjacent pairs, skipping anything reserved or already used this run."""
    stem = "".join(ch for ch in name.upper() if ch.isalnum())
    candidates = []
    if len(stem) >= 2:
        candidates.append(stem[0:2])
    candidates += [stem[0] + stem[i] for i in range(2, len(stem))]
    candidates += [stem[i] + stem[(i + 1) % len(stem)] for i in range(1, len(stem))]
    for code in candidates:
        if code not in RESERVED_PREFIXES and code not in used:
            used.add(code)
            return code + "_"
    raise ValueError("could not derive a unique prefix for %r" % name)


def used_names_in(wads, omg):
    """Texture (tx_up/tx_low/tx_mid) and flat (tx_floor/tx_ceil) names
    actually referenced by any map in any of `wads`."""
    textures, flats = set(), set()
    for wad in wads:
        for map_name in wad.maps.find("*"):
            m = omg.MapEditor(wad.maps[map_name])
            for sd in m.sidedefs:
                for tex_name in (sd.tx_up, sd.tx_low, sd.tx_mid):
                    if tex_name != NONE_TEX:
                        textures.add(tex_name)
            for sec in m.sectors:
                flats.add(sec.tx_floor)
                flats.add(sec.tx_ceil)
    return textures, flats


def level_number(map_name):
    """Trailing digits of a map name (MAP07 -> 7, E1M4 -> 4). None if the
    name has no trailing digits at all."""
    digits = ""
    for ch in reversed(map_name):
        if ch.isdigit():
            digits = ch + digits
        else:
            break
    return int(digits) if digits else None


def parse_legacy_mapinfo(text):
    """Parse old-style flat MAPINFO ('map MAP01 "Title"' followed by bare
    keyword-value lines, no braces) into {mapname: {title, music, sky1,
    par}}. Returns {} if the text looks like the newer curly-brace MAPINFO
    format instead -- a different format this doesn't attempt to parse."""
    result = {}
    current = None
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("//"):
            continue
        if "{" in line or "}" in line:
            return {}  # curly-brace-style MAPINFO, not this parser's format
        parts = line.split(None, 1)
        keyword = parts[0].lower()
        rest = parts[1].strip() if len(parts) > 1 else ""
        if keyword == "map":
            m = re.match(r'(\S+)\s+"([^"]*)"', rest)
            current = m.group(1).upper() if m else None
            if current:
                result[current] = {"title": m.group(2)}
        elif current and keyword in ("music", "sky1", "par") and rest:
            result[current][keyword] = rest.split()[0]
    return result


def source_mapinfo(wad):
    if "MAPINFO" not in wad.data:
        return {}
    return parse_legacy_mapinfo(wad.data["MAPINFO"].data.decode("latin1", errors="ignore"))


def rename_for(prefix, name):
    """A collision-renamed asset/map name, fit into Doom's 8-char lump
    limit. ponytail: plain truncation, not a collision-proof scheme -- fine
    for the one rename=true source in practice (Freedoom-shaped: an IWAD
    replacement, not an ordinary PWAD); revisit if a second rename=true
    source's truncated names collide with each other.
    """
    return (prefix + name)[:8]


def resolve_group(group, claimed_key, claimed, prefix, rename, out_subdir, ext):
    """Drop-or-rename every lump in `group` against `claimed[claimed_key]`,
    write survivors to `out_subdir`, and update `claimed` in place."""
    for lump_name in list(group.keys()):
        lump = group[lump_name]
        out_name = lump_name
        if lump_name in claimed[claimed_key]:
            if not rename:
                continue  # drop: existing claimant's definition wins
            out_name = rename_for(prefix, lump_name)
        claimed[claimed_key].add(out_name)
        lump.to_file(os.path.join(out_subdir, out_name + ext))


def discover_script_lumps(wad):
    """GZDoom's cumulative-type lumps present in `wad.data`, plus whatever
    they `#include` transitively (DECORATE's own fragment files, etc.) --
    whatever the actual set turns out to be, not a hardcoded list."""
    found = set()
    worklist = list(SAFE_SCRIPT_LUMPS & set(wad.data.keys()))
    while worklist:
        lump_name = worklist.pop()
        if lump_name in found:
            continue
        found.add(lump_name)
        text = wad.data[lump_name].data.decode("latin1", errors="ignore")
        for inc in _INCLUDE_RE.findall(text):
            inc = inc.upper()
            if inc in wad.data and inc not in found:
                worklist.append(inc)
    return found


def discover_loose_entries(container, claimed_members):
    """Every top-level file/directory in `container` not already consumed
    as a `maps`/`resourceWads` member."""
    files, dirs = [], set()
    with zipfile.ZipFile(container) as z:
        for member in z.namelist():
            if member in claimed_members or member.endswith("/"):
                continue
            if "/" in member:
                dirs.add(member.split("/", 1)[0])
            else:
                files.append(member)
    return files, dirs


def merge_wad_assets(wad, tex_used, flat_used, prefix, rename, claimed, dirs, merged_textures, Textures):
    """Dead-strip + collision-resolve one wad's textures/patches/flats/
    sprites/sounds/music against `claimed`, write survivors, and return
    (tex_rename, flat_rename) for rewriting map sidedef/sector references."""
    src_textures = Textures(wad.txdefs) if "TEXTURE1" in wad.txdefs else Textures()

    tex_rename = {}
    for tname in list(src_textures.keys()):
        if tname not in tex_used:
            del src_textures[tname]
            continue
        if tname in claimed["texture"]:
            if rename:
                new_name = rename_for(prefix, tname)
                tex_rename[tname] = new_name
                src_textures[new_name] = src_textures.pop(tname)
                src_textures[new_name].name = new_name
                claimed["texture"].add(new_name)
            else:
                del src_textures[tname]
            continue
        claimed["texture"].add(tname)
    merged_textures.update(src_textures)

    # Every kept texture is composed of PNAMES-referenced patch graphics --
    # without those actual patch lumps present, GZDoom renders the texture
    # as missing/checkerboard even though the TEXTURE1 definition is there.
    patch_used = {p.name for t in src_textures.values() for p in t.patches}
    for pname in patch_used:
        if pname not in wad.patches:
            continue  # referenced but supplied by the base IWAD, not this wad
        out_name = pname
        if pname in claimed["patch"]:
            if not rename:
                continue
            out_name = rename_for(prefix, pname)
            for t in src_textures.values():
                for p in t.patches:
                    if p.name == pname:
                        p.name = out_name
        claimed["patch"].add(out_name)
        wad.patches[pname].to_file(os.path.join(dirs["patches"], out_name + ".lmp"))

    flat_rename = {}
    for fname in flat_used:
        if fname not in wad.flats:
            continue  # referenced but supplied by the base IWAD, not this wad
        out_name = fname
        if fname in claimed["flat"]:
            if not rename:
                continue
            out_name = rename_for(prefix, fname)
            flat_rename[fname] = out_name
        claimed["flat"].add(out_name)
        wad.flats[fname].to_file(os.path.join(dirs["flats"], out_name + ".lmp"))

    # Sprites/sounds/music: no used-name computation possible from raw map
    # data (thing->sprite mapping lives in DECORATE/actor defs, not here)
    # -- carried through whole, same drop-or-rename policy.
    resolve_group(wad.sprites, "sprite", claimed, prefix, rename, dirs["sprites"], ".lmp")
    resolve_group(wad.sounds, "sound", claimed, prefix, rename, dirs["sounds"], ".lmp")
    resolve_group(wad.music, "music", claimed, prefix, rename, dirs["music"], ".mus")

    return tex_rename, flat_rename


def extract_maps(wad, prefix, tex_rename, flat_rename, dirs, mapinfo_lines, omg, info_by_map=None, map_names=None):
    info_by_map = info_by_map or {}
    count = 0
    for map_name in wad.maps.find("*"):
        m = omg.MapEditor(wad.maps[map_name])
        is_hexen = hasattr(m, "behavior")

        if tex_rename or flat_rename:
            for sd in m.sidedefs:
                sd.tx_up = tex_rename.get(sd.tx_up, sd.tx_up)
                sd.tx_low = tex_rename.get(sd.tx_low, sd.tx_low)
                sd.tx_mid = tex_rename.get(sd.tx_mid, sd.tx_mid)
            for sec in m.sectors:
                sec.tx_floor = flat_rename.get(sec.tx_floor, sec.tx_floor)
                sec.tx_ceil = flat_rename.get(sec.tx_ceil, sec.tx_ceil)

        out_name = rename_for(prefix, map_name)
        out_wad = omg.WAD()
        out_wad.maps[out_name] = m.to_lumps()
        out_wad.to_file(os.path.join(dirs["maps"], out_name + ".wad"))
        count += 1
        if map_names is not None:
            map_names.append(out_name)

        info = info_by_map.get(map_name, {})
        fields = []
        if is_hexen:
            num = level_number(map_name)
            if num is not None:
                fields.append("\tlevelnum = %d" % num)
        if "music" in info:
            fields.append('\tMusic = "%s"' % info["music"])
        if "sky1" in info:
            fields.append('\tSky1 = "%s"' % info["sky1"])
        if "par" in info:
            fields.append("\tPar = %s" % info["par"])
        if fields:
            title = info.get("title", out_name)
            mapinfo_lines.append('map %s "%s"\n{\n%s\n}\n' % (out_name, title, "\n".join(fields)))
    return count


def process_simple_source(path, used_prefixes, rename_assets, claimed, dirs, merged_textures, mapinfo_lines, map_names, omg, Textures):
    name = source_name(path)
    prefix = derive_prefix(name, used_prefixes)
    rename = name in rename_assets
    wad = omg.WAD(path)
    tex_used, flat_used = used_names_in([wad], omg)
    tex_rename, flat_rename = merge_wad_assets(
        wad, tex_used, flat_used, prefix, rename, claimed, dirs, merged_textures, Textures
    )
    count = extract_maps(
        wad, prefix, tex_rename, flat_rename, dirs, mapinfo_lines, omg, source_mapinfo(wad), map_names
    )
    print("  %s: %d maps" % (name, count))
    return count


def process_composite_source(src, used_prefixes, rename_assets, claimed, dirs, out_dir, merged_textures, mapinfo_lines, map_names, omg, Textures, tmpdir):
    name = src["name"]
    prefix = derive_prefix(name, used_prefixes)
    rename = name in rename_assets
    container = src["container"]

    def extract_member(member):
        dest = os.path.join(tmpdir, name, member.replace("/", "_"))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with zipfile.ZipFile(container) as z, z.open(member) as src_f, open(dest, "wb") as dst_f:
            shutil.copyfileobj(src_f, dst_f)
        return dest

    map_wads = [omg.WAD(extract_member(m)) for m in src["maps"]]
    resource_wads = [omg.WAD(extract_member(m)) for m in src.get("resourceWads", [])]

    tex_used, flat_used = used_names_in(map_wads, omg)
    tex_rename, flat_rename, info_by_map = {}, {}, {}
    for wad in resource_wads:
        t_ren, f_ren = merge_wad_assets(
            wad, tex_used, flat_used, prefix, rename, claimed, dirs, merged_textures, Textures
        )
        tex_rename.update(t_ren)
        flat_rename.update(f_ren)
        info_by_map.update(source_mapinfo(wad))

        for lump_name in discover_script_lumps(wad):
            wad.data[lump_name].to_file(os.path.join(out_dir, lump_name))

    claimed_members = set(src["maps"]) | set(src.get("resourceWads", []))
    loose_files, loose_dirs = discover_loose_entries(container, claimed_members)
    with zipfile.ZipFile(container) as z:
        for fname in loose_files:
            data = z.read(fname)
            dest = os.path.join(out_dir, os.path.basename(fname))
            mode = "ab" if os.path.exists(dest) else "wb"
            with open(dest, mode) as f:
                if mode == "ab":
                    f.write(b"\n")
                f.write(data)
        for dirname in loose_dirs:
            prefix_path = dirname + "/"
            for member in z.namelist():
                if member.startswith(prefix_path) and not member.endswith("/"):
                    dest = os.path.join(out_dir, member)
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with z.open(member) as src_f, open(dest, "wb") as dst_f:
                        shutil.copyfileobj(src_f, dst_f)

    count = 0
    for wad in map_wads:
        info_by_map.update(source_mapinfo(wad))
        count += extract_maps(wad, prefix, tex_rename, flat_rename, dirs, mapinfo_lines, omg, info_by_map, map_names)
    print("  %s: %d maps" % (name, count))
    return count


def main():
    manifest = json.load(open(sys.argv[1]))
    omg, Textures = load_omg(manifest["omgPath"])

    out_dir = manifest["outputDir"]
    dirs = {sub: os.path.join(out_dir, sub) for sub in ("maps", "flats", "patches", "sprites", "sounds", "music")}
    for d in dirs.values():
        os.makedirs(d, exist_ok=True)

    # doom_fusion.ipk3 is a zip (pk3), not a classic WAD -- omg.WAD() can't
    # open it directly. Read its claimed names straight from the archive
    # listing/lumps instead.
    with zipfile.ZipFile(manifest["baseIpk3"]) as z:
        names = set(z.namelist())
        claimed = {
            "flat": {os.path.splitext(os.path.basename(n))[0] for n in names if n.startswith("flats/")},
            "patch": {os.path.splitext(os.path.basename(n))[0] for n in names if n.startswith("patches/")},
            "sprite": {os.path.splitext(os.path.basename(n))[0] for n in names if n.startswith("sprites/")},
            "sound": {os.path.splitext(os.path.basename(n))[0] for n in names if n.startswith("sounds/")},
            "music": {os.path.splitext(os.path.basename(n))[0] for n in names if n.startswith("music/")},
        }
        if "TEXTURE1.lmp" in names and "PNAMES.lmp" in names:
            from omg.lump import Lump

            base_textures = Textures()
            base_textures.from_lumps(Lump(z.read("TEXTURE1.lmp")), Lump(z.read("PNAMES.lmp")))
            claimed["texture"] = set(base_textures.keys())
        else:
            claimed["texture"] = set()

        # WadFusion's own maps/*.wad names -- seeded into the same shuffle
        # list our own generated maps get appended to, so the ROGUEMAPS lump
        # (read by roguelike_shuffle.zs) covers everything, not just the
        # community-megawad additions. MOShuffle's own "Autoload MAPINFO"
        # mode was tried and rejected: its map-discovery expects one
        # unbroken sequential MAP01/MAP02/... run and silently stops at the
        # first mismatch, which never holds across multiple differently-
        # prefixed sources -- an explicit name list has no such limit.
        map_names = [os.path.splitext(os.path.basename(n))[0] for n in names if n.startswith("maps/")]

    merged_textures = Textures()
    mapinfo_lines = []
    used_prefixes = set()
    rename_assets = set(manifest.get("renameAssets", []))
    total_maps = 0

    with tempfile.TemporaryDirectory() as tmpdir:
        for src in manifest["sources"]:
            if isinstance(src, str):
                total_maps += process_simple_source(
                    src,
                    used_prefixes,
                    rename_assets,
                    claimed,
                    dirs,
                    merged_textures,
                    mapinfo_lines,
                    map_names,
                    omg,
                    Textures,
                )
            else:
                total_maps += process_composite_source(
                    src,
                    used_prefixes,
                    rename_assets,
                    claimed,
                    dirs,
                    out_dir,
                    merged_textures,
                    mapinfo_lines,
                    map_names,
                    omg,
                    Textures,
                    tmpdir,
                )

    if len(merged_textures):
        tex_group = merged_textures.to_lumps()
        tex_group["TEXTURE1"].to_file(os.path.join(out_dir, "TEXTURE1.lmp"))
        tex_group["PNAMES"].to_file(os.path.join(out_dir, "PNAMES.lmp"))

    if mapinfo_lines:
        with open(os.path.join(out_dir, "mapinfo.txt"), "w") as f:
            f.write("\n".join(mapinfo_lines))

    with open(os.path.join(out_dir, "ROGUEMAPS"), "w") as f:
        f.write("\n".join(map_names))

    print("Total: %d maps from %d sources (%d in shuffle pool)" % (total_maps, len(manifest["sources"]), len(map_names)))


if __name__ == "__main__":
    main()
