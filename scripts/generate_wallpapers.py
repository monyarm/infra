#!/usr/bin/env python3
"""Generate/merge wallpaper .nix stub entries from a terse text list.

Usage: python3 scripts/generate_wallpapers.py <input.txt>

See /home/monyarm/.claude/plans/i-d-like-a-script-lovely-teapot.md for the
full format spec and design rationale.
"""

import os
import re
import sys
from urllib.parse import urlparse

WALLPAPERS_ROOT = "hosts/home/monyarm/config/Backgrounds/wallpapers"

FETCHER_HOSTS = [
    (("pixiv.net", "pximg.net"), "fetchPixiv"),
    (("gelbooru.com",), "fetchGelbooru"),
    (("my.nintendo.com",), "fetchMyNintendo"),
    (("mediafire.com",), "fetchMediafire"),
    (("mega.nz", "mega.co.nz"), "fetchMega"),
]

IMAGE_PREFIXES = ("crop", "grow", "growEdge", "transform", "extractFrame")

IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_']*")
URL_RE = re.compile(r"https?://")


class GenError(Exception):
    pass


# ---------------------------------------------------------------- parsing --


def parse_input(text):
    blocks = []
    cur_path = None
    cur_entries = None
    for lineno, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line:
            continue
        if line.startswith("- "):
            if cur_entries is None:
                raise GenError(f"line {lineno}: entry line before any path header")
            cur_entries.append(parse_entry(line[2:].strip(), lineno))
        else:
            if cur_path is not None:
                blocks.append((cur_path, cur_entries))
            cur_path = line
            cur_entries = []
    if cur_path is not None:
        blocks.append((cur_path, cur_entries))
    if not blocks:
        raise GenError("no path headers found in input")
    return blocks


def parse_entry(rest, lineno):
    chunks = [c.strip() for c in rest.split(">")]
    head = chunks[0]
    pipeline = [c for c in chunks[1:] if c]

    tokens = head.split()
    if not tokens:
        raise GenError(f"line {lineno}: empty entry")
    name = tokens[0]
    rest_tokens = tokens[1:]

    url_idxs = [i for i, t in enumerate(rest_tokens) if URL_RE.match(t)]
    if len(url_idxs) != 1:
        raise GenError(
            f"line {lineno}: expected exactly one http(s) URL, found {len(url_idxs)}"
        )
    url_idx = url_idxs[0]
    url = rest_tokens[url_idx]
    pre = rest_tokens[:url_idx]
    if len(pre) > 1:
        raise GenError(
            f"line {lineno}: at most one fetcher-name token before the URL, got {pre}"
        )
    post = rest_tokens[url_idx + 1 :]
    if post:
        raise GenError(f"line {lineno}: unexpected tokens after URL: {post}")

    return {
        "name": name,
        "fetcher_override": pre[0] if pre else None,
        "url": url,
        "pipeline": pipeline,
        "lineno": lineno,
    }


# ------------------------------------------------------------- generation --


def detect_fetcher(url):
    host = urlparse(url).netloc.lower()
    for hosts, fetcher in FETCHER_HOSTS:
        if any(h in host for h in hosts):
            return fetcher
    return None


def has_extension(url):
    base = urlparse(url).path.rsplit("/", 1)[-1]
    return bool(re.search(r"\.[A-Za-z0-9]{1,5}$", base))


def classify_stage(stage):
    m = IDENT_RE.match(stage.strip())
    name = m.group(0) if m else stage.strip()
    return name, name.startswith(IMAGE_PREFIXES)


def build_entry(entry):
    """Returns (nix_text_without_leading_indent, required_names set, attr_name)."""
    name_token = entry["name"]
    url = entry["url"]
    fetcher = entry["fetcher_override"] or detect_fetcher(url)
    needs = {"lib"}

    if has_extension(url):
        attr_name = name_token
        explicit_filename = None
    else:
        if "." not in name_token:
            raise GenError(
                f"line {entry['lineno']}: URL has no extension, so name "
                f"'{name_token}' must include one (e.g. '{name_token}.jpg')"
            )
        attr_name = name_token.rsplit(".", 1)[0]
        explicit_filename = name_token

    if not IDENT_RE.fullmatch(attr_name):
        raise GenError(
            f"line {entry['lineno']}: '{attr_name}' is not a valid attr name"
        )

    pipeline_stages = entry["pipeline"].copy()
    for stage in pipeline_stages:
        stage_name, is_image = classify_stage(stage)
        needs.add("image" if is_image else stage_name)

    if fetcher is None:
        needs.add("pkgs")
        args = [f'url = "{url}";']
        if explicit_filename:
            args.append(f'name = "{explicit_filename}";')
        args.append("hash = lib.fakeHash;")
        call_head = "pkgs.fetchurl"
    else:
        needs.add(fetcher)
        args = [f'url = "{url}";', "sha256 = lib.fakeHash;"]
        call_head = fetcher
        if explicit_filename:
            needs.add("getFile")
            pipeline_stages.insert(0, f'getFile "{explicit_filename}"')

    if not pipeline_stages:
        arg_lines = "".join(f"    {a}\n" for a in args)
        body = f"  {attr_name} = {call_head} {{\n{arg_lines}  }};"
    else:
        arg_lines = "".join(f"      {a}\n" for a in args)
        call = f"    {call_head} {{\n{arg_lines}    }}"
        lines = [f"  {attr_name} =", call]
        for stage in pipeline_stages[:-1]:
            lines.append(f"    |> {stage}")
        lines.append(f"    |> {pipeline_stages[-1]};")
        body = "\n".join(lines)

    return body, needs, attr_name


# -------------------------------------------------------------- file I/O --


def format_header(names, multiline):
    plain = [n for n in names if n != "..."]
    if multiline:
        inner = "".join(f"  {n},\n" for n in plain) + "  ...\n"
        return "{\n" + inner + "}:"
    return "{ " + ", ".join(plain + ["..."]) + " }:"


def split_header(content):
    """Returns (header_names, multiline, with_clause, body_open_idx)."""
    if not content.startswith("{"):
        raise GenError("existing file does not start with '{'")
    depth = 0
    end = None
    for i, ch in enumerate(content):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    if end is None:
        raise GenError("could not find end of header lambda args")
    header_text = content[1:end]
    multiline = "\n" in header_text
    names = [n.strip() for n in header_text.split(",")]
    names = [n for n in names if n]
    rest = content[end + 1 :]
    if not rest.startswith(":"):
        raise GenError("header args not followed by ':'")
    rest = rest[1:]

    m = re.match(r"\s*with\s+([A-Za-z_][A-Za-z0-9_]*)\s*;", rest)
    with_clause = None
    if m:
        with_clause = m.group(1)
        rest = rest[m.end() :]

    stripped = rest.lstrip()
    consumed = len(rest) - len(stripped)
    if not stripped.startswith("{"):
        raise GenError("expected body attrset to start with '{'")
    body_open_idx = len(content) - len(rest) + consumed
    return names, multiline, with_clause, body_open_idx


def merge_file(path, entries_nix, required_names):
    with open(path) as file:
        content = file.read()
    names, multiline, with_clause, body_open_idx = split_header(content)

    body_close_idx = content.rstrip().rfind("}")
    if body_close_idx < body_open_idx:
        raise GenError(f"{path}: could not find closing '}}' of body attrset")
    body_inner = content[body_open_idx + 1 : body_close_idx]

    existing_attrs = set(
        re.findall(r"^\s{2}([A-Za-z_][A-Za-z0-9_']*)\s*=", body_inner, re.MULTILINE)
    )
    for _, _, attr_name in entries_nix:
        if attr_name in existing_attrs:
            raise GenError(
                f"{path}: attr '{attr_name}' already exists, refusing to overwrite"
            )

    plain_names = {n for n in names if n != "..."}
    if with_clause:
        plain_names.add(with_clause)
    all_needed = set(required_names) | plain_names
    if "..." in names:
        all_needed.discard("...")
    new_names_ordered = [n for n in names if n != "..."]
    new_names_ordered.extend(
        sorted(
            all_needed
            - set(new_names_ordered)
            - ({with_clause} if with_clause else set())
        )
    )

    header_str = format_header(new_names_ordered, multiline)

    with_str = ""
    if "image" in all_needed:
        with_str = f"\nwith {with_clause or 'image'};"
    elif with_clause:
        with_str = f"\nwith {with_clause};"

    new_entries_block = "\n\n".join(text for text, _, _ in entries_nix)
    body_new = body_inner.rstrip() + "\n\n" + new_entries_block + "\n"

    new_content = header_str + with_str + "\n{" + body_new + "}\n"
    with open(path, "w") as f:
        f.write(new_content)


def write_new_file(path, entries_nix, required_names):
    needs_image = "image" in required_names
    names = sorted(n for n in required_names if n != "...")
    header_str = format_header(names, multiline=True)
    with_str = "\nwith image;" if needs_image else ""
    entries_block = "\n\n".join(text for text, _, _ in entries_nix)
    content = header_str + with_str + "\n{\n" + entries_block + "\n}\n"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)


# ------------------------------------------------------------------- main --


def main(argv):
    if len(argv) != 2:
        print(f"Usage: {argv[0]} <input.txt>", file=sys.stderr)
        return 1

    with open(argv[1]) as file:
        text = file.read()
    blocks = parse_input(text)

    for rel_path, entries in blocks:
        entries_nix = [build_entry(e) for e in entries]
        required_names = set()
        for _, needs, _ in entries_nix:
            required_names |= needs

        out_path = os.path.join(WALLPAPERS_ROOT, rel_path + ".nix")
        if os.path.exists(out_path):
            merge_file(out_path, entries_nix, required_names)
            print(
                f"merged {len(entries_nix)} entr{'y' if len(entries_nix) == 1 else 'ies'} into {out_path}"
            )
        else:
            write_new_file(out_path, entries_nix, required_names)
            print(f"wrote {out_path}")

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except GenError as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)
