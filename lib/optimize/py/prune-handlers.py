#!/usr/bin/env python3
"""Build-time handler pruning for dynamic.nix's optimizeLibPath.

The outer eval no longer decides which handlers/*.nix ship in the sandboxed
lib copy (that used to be eval-time lib.fileset algebra over the whole
recorded file list); it just hands over the raw file list as JSON and this
script -- running inside the prep derivation -- reads the handler files'
own self-registered dispatch keys and prunes:

  - Each handler's keys = its implicit basename key ("png.nix" -> "png")
    plus every string literal in its exported `extensions = [...];` list(s)
    (jpeg/wad/deh/... self-register this way). The list is read with a
    comment/string-aware scan -- the same scanning approach trim-lib.py
    uses, biased the same way: ambiguous means keep, never drop.
  - A file whose `extensions` right-hand side ISN'T a literal list (e.g.
    archive.nix computes it from its `formats` attrset) can't be judged
    statically, so it always ships.
  - Any $exact / prefix* structural key makes a handler unconditional --
    those match filenames regardless of extension.
  - Extensions come from the recorded file list's basenames (lowercased,
    last dot segment). A handler survives iff one of its keys matches, or
    it's unconditional per the rules above.
  - doom/decorate + doom/wav ship only for doom-context archives; the
    caller passes the doom flag explicitly.

Usage: prune-handlers.py OUT_DIR FILELIST_JSON_PATH DOOM_ARG TRIM_LIB_PATH
  OUT_DIR: the assembled lib tree (pruned in place)
  FILELIST_JSON_PATH: JSON array of recorded file names, or literal null
  DOOM_ARG: literal "true"/"false"
  TRIM_LIB_PATH: path to trim-lib.py, whose comment/string-aware scanner is
    reused for the extensions extraction (passed explicitly because Nix
    materializes each ${./py/*.py} reference as its own store path, so a
    plain `import` can't see it)
"""

import importlib.util
import json
import os
import shutil
import sys

# Load trim-lib.py for skip_string_or_comment/skip_balanced instead of
# re-implementing them here.
_trim_spec = importlib.util.spec_from_file_location("trimlib", sys.argv[4])
assert _trim_spec is not None and _trim_spec.loader is not None
_trimlib = importlib.util.module_from_spec(_trim_spec)
_trim_spec.loader.exec_module(_trimlib)
skip_string_or_comment = _trimlib.skip_string_or_comment
skip_balanced = _trimlib.skip_balanced


def ident_bounds_ok(text, start, end):
    """True when text[start:end] isn't glued to a larger identifier."""
    before = text[start - 1] if start > 0 else ""
    after = text[end] if end < len(text) else ""
    ident_chars = set(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'"
    )
    return before not in ident_chars and after not in ident_chars


def extract_extension_keys(text):
    """Returns (keys, fully_understood): keys = every string literal found in
    any top-level `extensions = [...]` binding; fully_understood = False when
    an `extensions` binding exists whose value isn't a plain literal list
    (caller must keep the file). Comments/strings are skipped while hunting
    for the identifier so prose mentioning `extensions` can't false-positive,
    and literals are read with interpolation-aware skipping."""
    n = len(text)
    keys = []
    i = 0
    while i < n:
        skipped = skip_string_or_comment(text, i)
        if skipped is not None:
            i = skipped
            continue
        if text.startswith("extensions", i) and ident_bounds_ok(text, i, i + 10):
            j = i + 10
            while j < n and text[j].isspace():
                j += 1
            if j < n and text[j] == "=":
                j += 1
                while j < n and text[j].isspace():
                    j += 1
                if j < n and text[j] == "[":
                    # Literal list: harvest the string literals inside.
                    j += 1
                    while j < n:
                        skipped = skip_string_or_comment(text, j)
                        if skipped is not None:
                            lit = text[j:skipped]
                            if lit.startswith('"') and "${" not in lit:
                                keys.append(lit[1:-1])
                            elif lit.startswith('"'):
                                # Interpolated "key": not statically knowable.
                                return [], False
                            j = skipped
                            continue
                        if text[j] == "]":
                            break
                        if text[j] == "[":
                            # Nested structure we don't understand.
                            return [], False
                        j += 1
                    else:
                        return [], False
                else:
                    # Dynamic RHS (attrset lookup, function call, ...).
                    return [], False
        i += 1
    return keys, True


def main():
    out_dir, fl_path, doom_arg = sys.argv[1:4]
    with open(fl_path) as f:
        listing = json.load(f)

    handlers_dir = os.path.join(out_dir, "optimize", "handlers")
    if listing is not None and os.path.isdir(handlers_dir):
        exts = set()
        for entry in listing:
            base = os.path.basename(entry.rstrip("/"))
            i = base.rfind(".")
            if i > 0:
                exts.add(base[i + 1 :].lower())
        dropped = 0
        kept = 0
        for fn in sorted(os.listdir(handlers_dir)):
            if not fn.endswith(".nix"):
                continue
            path = os.path.join(handlers_dir, fn)
            with open(path) as f:
                text = f.read()
            declared, understood = extract_extension_keys(text)
            if not understood:
                kept += 1
                continue
            keys = [fn[: -len(".nix")]] + declared
            if any(k.startswith("$") or k.endswith("*") for k in keys):
                kept += 1
                continue
            if any(k.lower() in exts for k in keys):
                kept += 1
                continue
            os.unlink(path)
            dropped += 1
        print(
            f"prune-handlers: {len(exts)} extensions, kept {kept}, dropped {dropped}, doom {doom_arg}",
            file=sys.stderr,
        )
    else:
        print(
            "prune-handlers: no file list (or no handlers dir), keeping full set",
            file=sys.stderr,
        )

    if doom_arg != "true":
        shutil.rmtree(os.path.join(out_dir, "optimize", "doom"), ignore_errors=True)


if __name__ == "__main__":
    main()
