#!/usr/bin/env python3
"""Builds an ETF/OptiFine-compatible randomobs resource pack at Nix build
time. No network access, no vanilla client jar -- every input
(texturePacks, skins) is already a fetched path on disk, and the entity
path table below is static, already-verified data (see the plan this was
built from for exactly how each entry was confirmed), not derived live.

Per ETF's own docs (Traben-0/Entity_Texture_Features, RANDOM_GUIDE.md):
numbering starts at 2 -- index 1/default is always implicit and this
script never produces it. Villager profession/type/level layers and the
horse/sheep/iron_golem "secondary texture" auto-match feature are real
ETF capabilities but not built here yet -- ENTITY_PATHS below only ever
points at each entity's own base body texture.
"""
import argparse
import os
import shutil
import sys

from PIL import Image

# entity -> list of candidate relative paths under
# assets/minecraft/textures/entity/. Any entity NOT listed here defaults
# to ["<entity>/<entity>.png"] (the convention the vast majority of mobs
# follow). Only listed here when that default is wrong -- verified by
# directly unzipping the real 1.20.1 client jar, not guessed:
#   - donkey/mule/skeleton_horse/zombie_horse: separate real entities
#     that happen to store their vanilla texture inside horse's own
#     folder.
#   - horse: its own coat-color variants only (no single "horse.png");
#     the above four entities' files are correctly excluded since they're
#     listed under their own entity name instead.
#   - cat: no single "cat.png" -- explicit breed files.
ENTITY_PATHS = {
    "donkey": ["horse/donkey.png"],
    "mule": ["horse/mule.png"],
    "skeleton_horse": ["horse/horse_skeleton.png"],
    "zombie_horse": ["horse/horse_zombie.png"],
    "horse": [
        f"horse/horse_{c}.png"
        for c in ["black", "brown", "chestnut", "creamy", "darkbrown", "gray", "white"]
    ],
    "cat": [
        f"cat/{b}.png"
        for b in [
            "black",
            "red",
            "siamese",
            "british_shorthair",
            "calico",
            "jellie",
            "ocelot",
            "persian",
            "ragdoll",
            "tabby",
            "all_black",
            "white",
        ]
    ],
}


def candidate_paths(entity):
    return ENTITY_PATHS.get(entity, [f"{entity}/{entity}.png"])


def extract_candidates(pack_dir, entity):
    """Real file paths found on disk in this pack for this entity's known
    candidate slots -- a pack need not have all of them (e.g. it might
    only retexture 3 of cat's 12 breeds)."""
    base = os.path.join(pack_dir, "assets", "minecraft", "textures", "entity")
    return [
        os.path.join(base, rel)
        for rel in candidate_paths(entity)
        if os.path.isfile(os.path.join(base, rel))
    ]


def discover_entities(pack_dir):
    """Every entity this pack has a match for -- both the default
    convention (any entity/<name>/<name>.png, discovered by actually
    listing what subdirectories exist, not by checking a fixed list of
    known names) and the small ENTITY_PATHS override table (whose real
    files don't live at entity/<name>/<name>.png, e.g. donkey.png lives
    under horse/, not donkey/)."""
    base = os.path.join(pack_dir, "assets", "minecraft", "textures", "entity")
    found = set()
    if os.path.isdir(base):
        for name in os.listdir(base):
            if name not in ENTITY_PATHS and os.path.isfile(os.path.join(base, name, f"{name}.png")):
                found.add(name)
    for e in ENTITY_PATHS:
        if extract_candidates(pack_dir, e):
            found.add(e)
    return found


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--pack-format", type=int, required=True)
    p.add_argument("--texture-pack", action="append", default=[])
    p.add_argument("--skin", action="append", default=[], help="ENTITY=PATH, repeatable")
    p.add_argument("--out", required=True)
    args = p.parse_args()

    skins_by_entity = {}
    for s in args.skin:
        entity, _, path = s.partition("=")
        skins_by_entity.setdefault(entity, []).append(path)

    found = set()
    for pack in args.texture_pack:
        found |= discover_entities(pack)
    scope = sorted(set(skins_by_entity) | found)

    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, "pack.mcmeta"), "w") as f:
        f.write(
            '{ "pack": { "description": "randomobs", "pack_format": %d } }\n'
            % args.pack_format
        )

    for entity in scope:
        variants = []
        for pack in args.texture_pack:
            variants.extend(extract_candidates(pack, entity))
        variants.extend(skins_by_entity.get(entity, []))
        if not variants:
            sys.exit(
                f"mkRandomobs: entity '{entity}' has no texturePack match and no skins assigned"
            )

        out_dir = os.path.join(
            args.out, "assets", "minecraft", "optifine", "random", "entity", entity
        )
        os.makedirs(out_dir, exist_ok=True)

        ref_size = None
        for i, src in enumerate(variants):
            with Image.open(src) as im:
                if ref_size is None:
                    ref_size = im.size
                elif im.size != ref_size:
                    sys.exit(
                        f"mkRandomobs: entity '{entity}' variant {src} is {im.size}, "
                        f"expected {ref_size} -- rejecting mixed dimensions"
                    )
            # ETF: numbering always starts at 2 -- index 1/default is
            # implicit and must never be produced by this pack.
            shutil.copyfile(src, os.path.join(out_dir, f"{entity}{i + 2}.png"))


if __name__ == "__main__":
    main()
