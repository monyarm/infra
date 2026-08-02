#!/usr/bin/env python3
import base64
import fnmatch
import hashlib
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
import zipfile
from urllib.parse import urlparse

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0"

# .pk3/.ipk3 are GZDoom containers that are just zip files under the hood;
# listing what's inside them (in addition to the outer archive's own file
# list) lets the Nix side extract/optimize/repack their members without
# needing IFD -- the member names just need to be a static fact in
# sources.nix, known before any of that building happens.
PK3_EXTENSIONS = (".pk3", ".ipk3")


def zip_member_path(info):
    """Zip member paths as some tools (typically Windows-authored) store
    them can use literal backslashes as separators; Python's zipfile module
    returns that raw stored name unmodified, but unzip(1) -- what actually
    extracts these at build time -- converts them to real subdirectories.
    Recorded paths need to match that real on-disk layout, not the raw
    stored name, or getFile's cp lookups miss."""
    return info.filename.replace("\\", "/")


def scan_archive_contents_bytes(data):
    """Given a pk3/ipk3's raw bytes, return its sorted internal file list, or None if it's not a readable zip."""
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            return sorted(
                zip_member_path(info) for info in z.infolist()
                if not info.filename.endswith('/') and not info.is_dir()
            )
    except zipfile.BadZipFile:
        return None


def scan_archive_contents_from_zip(z):
    """Given an already-open outer zipfile.ZipFile, list the contents of any pk3/ipk3 members found inside it.

    Keyed by basename, not the full path within the outer archive: the Nix
    side (getFile + optimizePk3) always looks a pk3 up by basename (getFile
    extracts baseNameOf filePath for both naming and .originalName), so a
    full-path key here would just never match for any pk3 sitting in a
    subfolder.
    """
    result = {}
    for info in z.infolist():
        if info.filename.endswith('/') or info.is_dir():
            continue
        if info.filename.lower().endswith(PK3_EXTENSIONS):
            contents = scan_archive_contents_bytes(z.read(info.filename))
            if contents is not None:
                result[os.path.basename(zip_member_path(info))] = contents
    return result


def scan_archive_contents_from_dir(root_dir):
    """Walk an already-extracted directory tree, listing the contents of any pk3/ipk3 files found inside it.

    Keyed by basename -- see scan_archive_contents_from_zip's docstring.
    """
    result = {}
    for root, _, filenames in os.walk(root_dir):
        for fn in filenames:
            if not fn.lower().endswith(PK3_EXTENSIONS):
                continue
            full_path = os.path.join(root, fn)
            with open(full_path, "rb") as f:
                contents = scan_archive_contents_bytes(f.read())
            if contents is not None:
                result[fn] = contents
    return result


def parse_toml(content):
    data = {}
    current_section = None
    
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
            
        if line.startswith('[') and line.endswith(']'):
            current_section = line[1:-1].strip()
            data[current_section] = {}
        elif '=' in line:
            if current_section is None:
                raise ValueError("Key-value pair found before any section")
                
            key, val = line.split('=', 1)
            key = key.strip()
            val = val.strip()
            
            if (key.startswith('"') and key.endswith('"')) or (key.startswith("'") and key.endswith("'")):
                key = key[1:-1]
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]
                
            data[current_section][key] = val
            
    return data


def load_previous_nix(nix_path):
    if not os.path.exists(nix_path):
        return {}
        
    try:
        res = subprocess.run(
            ["nix", "eval", "--json", "-f", nix_path],
            capture_output=True,
            text=True,
            check=True
        )
        nested = json.loads(res.stdout)
        flat = {}
        
        def flatten(d, prefix=""):
            for k, v in d.items():
                key = f"{prefix}.{k}" if prefix else k
                # archiveContent is keyed by literal filenames (which may contain
                # dots, e.g. "Paranoid.pk3"), not a namespace grouping like the
                # rest of this tree -- treat it as an opaque leaf so those dots
                # don't get mistaken for flatten's own path separator and
                # split back apart into nested attrs on the next run.
                if k == "archiveContent":
                    flat[key] = v
                elif isinstance(v, dict) and "type" not in v:
                    flatten(v, key)
                else:
                    flat[key] = v
                    
        flatten(nested)
        return flat
    except Exception as e:
        print(f"Warning: Could not parse old {nix_path} ({e}). Performing full calculation.", file=sys.stderr)
        return {}



def calculate_sri_hash(data):
    sha256_digest = hashlib.sha256(data).digest()
    b64_hash = base64.b64encode(sha256_digest).decode('utf-8')
    return f"sha256-{b64_hash}"


def process_url(name, url):
    print(f"Updating [url] {name} from {url}...")
    data = download_file(url)
    h = calculate_sri_hash(data)
    return {
        "type": "url",
        "url": url,
        "hash": h
    }


def process_zip(name, url):
    print(f"Updating [zip] {name} from {url}...")
    data = download_file(url)
    h = calculate_sri_hash(data)
    
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        files = []
        for info in z.infolist():
            if not info.filename.endswith('/') and not info.is_dir():
                files.append(zip_member_path(info))
        archive_content = scan_archive_contents_from_zip(z)

    files.sort()
    result = {
        "type": "zip",
        "url": url,
        "hash": h,
        "files": files
    }
    if archive_content:
        result["archiveContent"] = archive_content
    return result


def parse_git_url(url):
    if '#' in url:
        return url.split('#', 1)
        
    parsed = urlparse(url)
    if 'github.com' in parsed.netloc:
        parts = [p for p in parsed.path.split('/') if p]
        if len(parts) > 2:
            git_url = f"https://github.com/{parts[0]}/{parts[1].removesuffix('.git')}.git"
            branch_or_tag = '/'.join(parts[2:])
            return git_url, branch_or_tag
        elif len(parts) == 2:
            git_url = f"https://github.com/{parts[0]}/{parts[1].removesuffix('.git')}.git"
            return git_url, None
            
    return url, None


def resolve_git_ref(git_url, branch_or_tag):
    cmd = ["git", "ls-remote", git_url]
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    
    refs = {}
    for line in res.stdout.strip().split('\n'):
        if not line:
            continue
        sha, ref = line.split('\t')
        refs[ref] = sha
        
    if not branch_or_tag:
        if 'HEAD' in refs:
            return refs['HEAD'], None
        raise ValueError(f"Could not find HEAD ref for {git_url}")
        
    td = f"refs/tags/{branch_or_tag}^{{}}"
    tr = f"refs/tags/{branch_or_tag}"
    hr = f"refs/heads/{branch_or_tag}"
    
    if td in refs:
        return refs[td], td
    if tr in refs:
        return refs[tr], tr
    if hr in refs:
        return refs[hr], hr
        
    for ref, sha in refs.items():
        if ref.endswith(f"/{branch_or_tag}"):
            return sha, ref
            
    if len(branch_or_tag) == 40 and all(c in '0123456789abcdefABCDEF' for c in branch_or_tag):
        return branch_or_tag, None
        
    raise ValueError(f"Could not resolve branch/tag {branch_or_tag} for {git_url}")


def extract_hash_from_nix_build(nix_expr, identifier_for_error):

    # get hash type from nix_expr (sha256 or sha1)
    hash_type_match = re.search(r'hash\s*=\s*"([^"]+)"', nix_expr)
    if not hash_type_match:
        raise ValueError(f"Could not find hash type in nix expression for {identifier_for_error}")
    hash_placeholder = hash_type_match.group(1)
    hash_type = hash_placeholder.split('-', 1)[0]  


    res = subprocess.run(["bash", "-c", f"nix build --impure --quiet --builders '' --no-link --expr '{nix_expr}' || true"], capture_output=True, text=True)
    output = res.stderr + res.stdout
    
    match = re.search(rf"got:\s+({hash_type}-[A-Za-z0-9+/=]+)", output)
    if match:
        return match.group(1)
        
    match_hex = re.search(rf"got:\s+({hash_type}-[a-f0-9]{{64}}|[a-f0-9]{{64}})", output)
    if match_hex:
        matched_str = match_hex.group(1)
        hex_hash = matched_str[7:] if matched_str.startswith(hash_type) else matched_str
        return hash_type + base64.b64encode(bytes.fromhex(hex_hash)).decode('utf-8')
        
    match_b32 = re.search(r"got:\s+([a-z0-9]{52})", output)
    if match_b32:
        res_conv = subprocess.run(["nix", "hash", "to-sri", "--type", hash_type, match_b32.group(1)], capture_output=True, text=True)
        if res_conv.returncode == 0:
            return res_conv.stdout.strip()
            
    raise ValueError(f"Failed to get hash for {identifier_for_error}. Nix build output:\n{output}")


def get_git_metadata(name, git_url, rev):
    with tempfile.TemporaryDirectory() as temp_dir:
        subprocess.run(["git", "init", "-q"], cwd=temp_dir, check=True)
        subprocess.run(["git", "remote", "add", "origin", git_url], cwd=temp_dir, check=True)
        subprocess.run(["git", "fetch", "-q", "--depth=1", "origin", rev], cwd=temp_dir, check=True)
        
        # Silence the check: suppress stderr
        has_submodules = subprocess.run(["git", "cat-file", "-e", f"{rev}:.gitmodules"], 
                                        cwd=temp_dir, stderr=subprocess.DEVNULL).returncode == 0
        has_gitattributes = subprocess.run(["git", "cat-file", "-e", f"{rev}:.gitattributes"], 
                                           cwd=temp_dir, stderr=subprocess.DEVNULL).returncode == 0
        
        res_files = subprocess.run(["git", "ls-tree", "-r", "--name-only", rev], cwd=temp_dir, capture_output=True, text=True, check=True)
        res_date = subprocess.run(["git", "log", "-1", "--format=%as", rev], cwd=temp_dir, capture_output=True, text=True, check=True)
        
        files = res_files.stdout.splitlines()
        files.sort()
        commit_date = res_date.stdout.strip()

        # Route logic: Simple repos use fast hash, Complex repos use authoritative nix-build
        if not has_submodules and not has_gitattributes:
            res_tree = subprocess.run(["git", "rev-parse", f"{rev}^{{tree}}"], cwd=temp_dir, capture_output=True, text=True, check=True)
            return files, res_tree.stdout.strip(), commit_date
        else:
            print(f"  -> Complex repo detected for {name}, falling back to Nix for hash calculation...")
            nix_expr = (
                f"let\n"
                f"  pkgs = import <nixpkgs> {{}};\n"
                f"  customLib = import ./lib {{\n"
                f"    inherit pkgs;\n"
                f"    inherit (pkgs) lib system;\n"
                f"    mkOutOfStoreSymlink = _x: {{}};\n"
                f"    config = {{}};\n"
                f"  }};\n"
                f"in\n"
                f"  customLib.fetchGitTree {{\n"
                f'    name = "{name}";\n'
                f'    url = "{git_url}";\n'
                f'    rev = "{rev}";\n'
                f'    date = "{commit_date}";\n'
                f'    hash = "sha1-AAAAAAAAAAAAAAAAAAAAAAAAAAA=";\n'
                f"  }}"
            )
            return files, extract_hash_from_nix_build(nix_expr, f"fetchGitTree ({name})"), commit_date

def process_git(name, url):
    print(f"Updating [git] {name} from {url}...")
    git_url, branch_or_tag = parse_git_url(url)
    rev, ref = resolve_git_ref(git_url, branch_or_tag)
    
    files, tree_hash, commit_date = get_git_metadata(name, git_url, rev)
    
    result = {
        "type": "git",
        "url": git_url,
        "rev": rev,
        "date": commit_date,
        "hash": tree_hash,
        "files": files
    }
    if ref:
        result["ref"] = ref
    return result

def semver_sort_key(tag):
    if tag.startswith("refs/tags/"):
        tag = tag[len("refs/tags/"):]
        
    parts = re.split(r'[-+]', tag, 1)
    
    def to_natural_key(s):
        if s.startswith('v') or s.startswith('V'):
            s = s[1:]
        return [(0, int(tok)) if tok.isdigit() else (1, tok) for tok in re.split(r'(\d+)', s) if tok]
        
    release_key = to_natural_key(parts[0])
    has_no_prerelease = 1 if len(parts) == 1 else 0
    prerelease_key = to_natural_key(parts[1]) if len(parts) > 1 else []
    
    return (release_key, has_no_prerelease, prerelease_key)


def get_git_tags(url):
    res = subprocess.run(["git", "ls-remote", "--tags", url], capture_output=True, text=True, check=True)
    tags = {}
    
    for line in res.stdout.strip().split('\n'):
        if not line:
            continue
        sha, ref = line.split('\t')
        
        is_peeled = ref.endswith("^{}")
        tag_name = ref[10:-3] if is_peeled else ref[10:]
        
        if is_peeled or tag_name not in tags:
            tags[tag_name] = sha
        
    return tags


def process_git_tag(name, url):
    print(f"Updating [git-tag] {name} from {url}...")
    git_url, _ = parse_git_url(url)
    tags = get_git_tags(git_url)
    
    if not tags:
        raise ValueError(f"No tags found for git-tag source {name} at {git_url}")
        
    latest_tag = sorted(tags.keys(), key=semver_sort_key)[-1]
    rev = tags[latest_tag]
    
    files, true_hash, commit_date = get_git_metadata(name, git_url, rev)
    
    return {
        "type": "git-tag",
        "url": git_url,
        "rev": rev,
        "date": commit_date,
        "hash": true_hash,
        "ref": f"refs/tags/{latest_tag}",
        "tag": latest_tag,
        "files": files
    }


def make_nix_src_expr(info):
    t = info["type"]
    if t in ["git", "git-tag"]:
        return f'customLib.fetchGitTree {{ url = "{info["url"]}"; rev = "{info["rev"]}"; hash = "{info["hash"]}"; date = "{info["date"]}"; }}'
    elif t == "zip":
        return f'pkgs.fetchzip {{ url = "{info["url"]}"; hash = "{info["hash"]}"; }}'
    elif t == "url":
        return f'pkgs.fetchurl {{ url = "{info["url"]}"; hash = "{info["hash"]}"; }}'
    elif t == "idgames":
        game_val = str(info["game"]) if isinstance(info["game"], int) else f'"{info["game"]}"'
        return f'customLib.fetchIdGames {{ game = {game_val}; version = "{info["version"]}"; hash = "{info["hash"]}"; }}'
    raise ValueError(f"Unsupported parent source type '{t}'")


def check_vendor_cache(name, source_name, results, previous_sources):
    if name not in previous_sources:
        return None
        
    old_vendor = previous_sources[name]
    if old_vendor.get("source") != source_name or source_name not in results:
        return None
        
    current_parent = results[source_name]
    old_parent = previous_sources.get(source_name)
    if not old_parent:
        return None
        
    if current_parent.get("hash") == old_parent.get("hash") and current_parent.get("rev") == old_parent.get("rev"):
        print(f"  -> Cache hit for {name}! Parent '{source_name}' hasn't changed.")
        return old_vendor.get("hash")
        
    return None


def process_go(name, source_name, results, previous_sources):
    if source_name not in results:
        raise ValueError(f"Go vendor '{name}' references missing source '{source_name}'.")
        
    cached_hash = check_vendor_cache(name, source_name, results, previous_sources)
    if cached_hash:
        return {"type": "go", "source": source_name, "hash": cached_hash}
        
    print(f"Updating [go] {name} using source {source_name}...")
    
    src_expr = make_nix_src_expr(results[source_name])
    nix_expr = (
        f"let\n"
        f"  pkgs = import <nixpkgs> {{}};\n"
        f"  customLib = import ./lib {{\n"
        f"    inherit pkgs;\n"
        f"    inherit (pkgs) lib system;\n"
        f"    mkOutOfStoreSymlink = _x: {{}};\n"
        f"    config = {{}};\n"
        f"  }};\n"
        f"  src = {src_expr};\n"
        f"in\n"
        f"  (pkgs.buildGoModule {{\n"
        f'    pname = "go-vendor-calc";\n'
        f'    version = "0.0.1";\n'
        f"    inherit src;\n"
        f'    vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";\n'
        f"  }}).goModules"
    )
    return {"type": "go", "source": source_name, "hash": extract_hash_from_nix_build(nix_expr, f"go-vendor {name}")}


def process_npm(name, source_name, results, previous_sources):
    if source_name not in results:
        raise ValueError(f"NPM vendor '{name}' references missing source '{source_name}'.")
        
    cached_hash = check_vendor_cache(name, source_name, results, previous_sources)
    if cached_hash:
        return {"type": "npm", "source": source_name, "hash": cached_hash}
        
    print(f"Updating [npm] {name} using source {source_name}...")
    
    src_expr = make_nix_src_expr(results[source_name])
    nix_expr = (
        f"let\n"
        f"  pkgs = import <nixpkgs> {{}};\n"
        f"  customLib = import ./lib {{\n"
        f"    inherit pkgs;\n"
        f"    inherit (pkgs) lib system;\n"
        f"    mkOutOfStoreSymlink = _x: {{}};\n"
        f"    config = {{}};\n"
        f"  }};\n"
        f"  src = {src_expr};\n"
        f"in\n"
        f"  (pkgs.buildNpmPackage {{\n"
        f'    pname = "npm-vendor-calc";\n'
        f'    version = "0.0.1";\n'
        f"    inherit src;\n"
        f'    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";\n'
        f"  }}).npmDeps"
    )
    return {"type": "npm", "source": source_name, "hash": extract_hash_from_nix_build(nix_expr, f"npm-vendor {name}")}


def process_custom(fetcher_name, name, url):
    print(f"Updating [{fetcher_name}] {name} from {url}...")
    nix_expr = (
        f"let\n"
        f"  pkgs = import <nixpkgs> {{}};\n"
        f"  customLib = import ./lib {{\n"
        f"    inherit pkgs;\n"
        f"    inherit (pkgs) lib system;\n"
        f"    mkOutOfStoreSymlink = _x: {{}};\n"
        f"    config = {{}};\n"
        f"  }};\n"
        f"in\n"
        f"  customLib.{fetcher_name} {{\n"
        f'    name = "{name}";\n'
        f'    url = "{url}";\n'
        f'    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";\n'
        f'    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";\n'
        f"  }}"
    )
    return {
        "type": fetcher_name,
        "url": url,
        "hash": extract_hash_from_nix_build(nix_expr, f"custom fetcher {fetcher_name} ({name})")
    }


def get_gdrive_version_hint(file_id):
    """Best-effort cheap version check via a HEAD request. Returns None when
    unavailable (large files land behind Google's "can't scan for viruses"
    confirmation page instead of serving Content-Length/ETag directly) --
    the caller should always re-verify in that case rather than cache."""
    url = f"https://drive.google.com/uc?id={file_id}&export=download"
    try:
        req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=10) as resp:
            length = resp.headers.get("Content-Length")
            etag = resp.headers.get("ETag")
            if length or etag:
                return f"{length}:{etag}"
    except Exception:
        pass
    return None


def process_gdrive(name, raw, previous_sources):
    old = previous_sources.get(name)
    file_id, extra = parse_source_spec(raw)
    extract = bool(extra.get("extract"))
    out_name = extra.get("name")

    print(f"Checking [gdrive] {name} (fileId {file_id})...")
    version = get_gdrive_version_hint(file_id)

    if version is not None and old and old.get("fileId") == file_id and old.get("version") == version:
        print(f"  -> {name} unchanged (Content-Length/ETag matches); reusing cached hash.")
        return old

    print(f"  -> Fetching hash for {name} via Nix build...")
    fetch_args = {"fileId": f'"{file_id}"'}
    if extract:
        fetch_args["extract"] = "true"
    if out_name:
        fetch_args["name"] = f'"{out_name}"'
    nix_expr = nix_build_expr("fetchGDrive", fetch_args)
    h = extract_hash_from_nix_build(nix_expr, f"fetchGDrive ({name})")

    print(f"  -> Realizing {name}'s output to record its file list...")
    store_path = realize_build_output("fetchGDrive", fetch_args, h)
    files, archive_content = scan_realized_output(store_path, out_name or file_id)

    result = {"type": "gdrive", "fileId": file_id, "hash": h}
    if extract:
        result["extract"] = True
    if out_name:
        result["name"] = out_name
    if version is not None:
        result["version"] = version
    if files:
        result["files"] = files
    if archive_content:
        result["archiveContent"] = archive_content
    return result


def mediafire_default_name(url):
    """Mirrors fetchMediafire's own `name ?` default (lib/fetchers/mediafire.nix):
    prefer the filename segment of a .../file/<id>/<filename>/file URL, else
    fall back to the URL's last path segment."""
    m = re.match(r".*/file/[^/]+/([^/]+)/file/?$", url)
    if m:
        return m.group(1)
    m2 = re.match(r".*/([^/]+)$", url.split("?")[0].split("#")[0])
    return m2.group(1) if m2 else url


def process_mediafire(name, raw, previous_sources):
    old = previous_sources.get(name)
    url, extra = parse_source_spec(raw)
    extract = bool(extra.get("extract"))

    print(f"Checking [mediafire] {name} from {url}...")

    # Mediafire quickkeys (the id segment in /file/<quickkey>/...) are
    # permalinks to one specific uploaded file version -- if the author
    # replaces the file, mediafire assigns a new quickkey/URL rather than
    # mutating this one. Unchanged URL therefore means unchanged content,
    # no HTTP call needed at all to confirm it.
    if old and old.get("url") == url:
        print(f"  -> {name} unchanged (mediafire quickkey is a permalink); reusing cached hash.")
        return old

    print(f"  -> Fetching hash for {name} via Nix build...")
    fetch_args = {"url": f'"{url}"'}
    if extract:
        fetch_args["extract"] = "true"
    nix_expr = nix_build_expr("fetchMediafire", fetch_args)
    h = extract_hash_from_nix_build(nix_expr, f"fetchMediafire ({name})")

    print(f"  -> Realizing {name}'s output to record its file list...")
    store_path = realize_build_output("fetchMediafire", fetch_args, h)
    files, archive_content = scan_realized_output(store_path, mediafire_default_name(url))

    result = {"type": "mediafire", "url": url, "hash": h}
    if extract:
        result["extract"] = True
    if files:
        result["files"] = files
    if archive_content:
        result["archiveContent"] = archive_content
    return result


def resolve_moddb_url(mod_id):
    """Cheaply resolves ModDB's download-start page to the final CDN path,
    without downloading the file body -- mirrors fetchModDB's own curl
    invocation (same --tls-max 1.2 workaround for Cloudflare's bot-management
    fingerprinting the mod.nix comment describes) so it hits the same code
    path moddb.com actually allows through.

    Returns just the URL path (e.g. "/dl/2026/04/07/foo.rar"), not the full
    URL -- the CDN load-balances across hostnames (fmt4/fmt5/...) and signs
    each redirect with a fresh, per-request token/expiry query string, both
    of which change on every resolve even for the exact same file. Only the
    path (which embeds the upload date and filename) is a stable signal."""
    headers = ["--tls-max", "1.2", "--header", "Referer: https://www.moddb.com/", "--user-agent", USER_AGENT]
    start_url = f"https://www.moddb.com/downloads/start/{mod_id}/all"
    page = subprocess.run(["curl", "-s", *headers, start_url], capture_output=True, text=True, check=True).stdout
    m = re.search(r'href="(/downloads/mirror/[^"]*)"', page)
    if not m:
        return None
    mirror_url = "https://www.moddb.com" + m.group(1)
    head = subprocess.run(["curl", "-sI", *headers, mirror_url], capture_output=True, text=True, check=True).stdout
    loc = re.search(r"(?im)^location:\s*(\S+)", head)
    if not loc:
        return None
    return urllib.parse.urlparse(loc.group(1).strip()).path


def process_moddb(name, raw, previous_sources):
    old = previous_sources.get(name)
    mod_id = raw

    print(f"Checking [moddb] {name} (download {mod_id})...")

    # ModDB ids are nominally pinned, but an author can silently replace the
    # file behind an existing id (no new id gets minted, unlike itch's
    # versioned uploads) -- the resolved CDN URL embeds an upload date
    # (.../dl/2026/04/07/...), so it changes when that happens even though
    # the id and mirror-page URL don't. That's a cheap (two small requests,
    # no file download) and much more reliable signal than re-downloading
    # the whole file (sometimes 100+ MiB) on every run just to hash-compare.
    resolved_url = None
    try:
        resolved_url = resolve_moddb_url(mod_id)
    except Exception as e:
        print(f"  -> Couldn't resolve moddb's current download URL ({e}).")

    if old and old.get("id") == mod_id:
        if resolved_url is not None and resolved_url == old.get("resolvedUrl"):
            print(f"  -> {name} unchanged (resolved download URL matches); reusing cached hash.")
            return old
        if resolved_url is None:
            print(f"  -> Couldn't confirm moddb's current download URL; reusing cached hash without re-verifying.")
            return old
        print(f"  -> {name}'s resolved download URL changed; re-verifying via a real fetch.")
        print(f"     old: {old.get('resolvedUrl')!r}")
        print(f"     new: {resolved_url!r}")

    print(f"  -> Fetching hash for {name} via Nix build...")
    nix_expr = nix_build_expr("fetchModDB", {"id": mod_id})
    h = extract_hash_from_nix_build(nix_expr, f"fetchModDB ({name})")

    print(f"  -> Realizing {name}'s output to record its file list...")
    store_path = realize_build_output("fetchModDB", {"id": mod_id}, h)
    files, archive_content = scan_realized_output(store_path)

    result = {"type": "moddb", "id": mod_id, "hash": h}
    if resolved_url is not None:
        result["resolvedUrl"] = resolved_url
    if files:
        result["files"] = files
    if archive_content:
        result["archiveContent"] = archive_content
    return result


def list_itch_uploads(url):
    api_key = os.environ.get("ITCH_API_KEY")
    if not api_key:
        raise RuntimeError(
            "ITCH_API_KEY is not set. itch.io's API requires a key for every "
            "operation, even public games. Get one at https://itch.io/user/settings/api-keys."
        )

    data_json_url = url.rstrip('/') + '/data.json'
    game_id = json.loads(download_file(data_json_url))["id"]

    uploads_url = f"https://api.itch.io/games/{game_id}/uploads?api_key={api_key}"
    uploads = json.loads(download_file(uploads_url))["uploads"]
    return game_id, uploads


def get_itch_metadata(url):
    try:
        _, uploads = list_itch_uploads(url)
    except Exception as e:
        print(f"  -> Couldn't read itch.io upload metadata ({e}); falling back to a real fetch to check.", file=sys.stderr)
        return None

    fingerprint = sorted(f"{u.get('id')}:{u.get('md5_hash')}:{u.get('updated_at')}" for u in uploads)
    return "|".join(fingerprint)


# Filename substrings (case-insensitive) that mean "not the actual game,"
# regardless of how the developer tagged it -- platform traits are often set
# carelessly (e.g. every upload checked "Windows" including a press kit).
ITCH_UPLOAD_BLACKLIST = ["presskit", "press kit"]


def select_itch_upload(uploads, platform, file_match="*"):
    platform_traits = {"p_windows", "p_linux", "p_osx"}

    def is_blacklisted(u):
        name = (u.get("filename") or "").lower()
        return any(term in name for term in ITCH_UPLOAD_BLACKLIST)

    def is_tagged_for_platform(u):
        traits = u.get("traits") or []
        return u.get("type") == "default" and f"p_{platform}" in traits

    def matches_platform_loose(u):
        if u.get("type") != "default":
            return True
        traits = u.get("traits") or []
        # An upload with no OS trait at all isn't platform-restricted (itch
        # just didn't tag it), so treat it as matching every platform rather
        # than excluding it outright.
        if not platform_traits.intersection(traits):
            return True
        return f"p_{platform}" in traits

    named = [
        u for u in uploads
        if fnmatch.fnmatch(u.get("filename", ""), file_match) and not is_blacklisted(u)
    ]
    # Prefer an upload actually tagged for this platform over the loose
    # "untagged, so it matches everything" fallback -- otherwise an
    # unrelated untagged upload (e.g. a press kit) can outrank the real
    # build just by sorting first (verified: exactly what happened to
    # wad.venturous when its itch page grew a press-kit upload).
    candidates = [u for u in named if is_tagged_for_platform(u)] or [
        u for u in named if matches_platform_loose(u)
    ]
    if not candidates:
        seen = [(u.get("filename"), u.get("type"), u.get("traits")) for u in uploads]
        raise ValueError(f"No upload matched platform={platform!r} fileMatch={file_match!r}. Uploads seen: {seen}")
    return candidates[0]


def fetch_itch_asset(name, url, system=None):
    game_id, uploads = list_itch_uploads(url)
    upload = select_itch_upload(uploads, system or "linux")

    api_key = os.environ["ITCH_API_KEY"]
    dl_url = f"https://api.itch.io/uploads/{upload['id']}/download?api_key={api_key}"
    data = download_file(dl_url)
    return data, upload["filename"]


def replicate_fetchitch_output(data, filename, out_name):
    for tool in (
        ("unzip",) if filename.lower().endswith(".zip") else
        ("tar",) if filename.lower().endswith((".tar.gz", ".tgz", ".tar.xz", ".txz")) else
        # unrar handles some real-world RAR files that p7zip's bundled rar
        # codec fails on ("Can not open the file as archive"), matching
        # extractArchiveSnippet's mime-based dispatch in lib/fetchers.nix.
        ("unrar",) if filename.lower().endswith(".rar") else
        ("7z",) if filename.lower().endswith((".7z", ".exe")) else ()
    ):
        if not shutil.which(tool):
            raise RuntimeError(f"'{tool}' is required to extract {filename} the same way fetchItch does, but isn't on PATH.")

    work_dir = tempfile.mkdtemp(prefix="itch-work-")
    out_dir = os.path.join(work_dir, out_name)
    os.makedirs(out_dir, exist_ok=True)
    src_dir = os.path.join(work_dir, "src")
    os.makedirs(src_dir, exist_ok=True)
    src_path = os.path.join(src_dir, filename)
    with open(src_path, "wb") as f:
        f.write(data)

    lower = filename.lower()
    if lower.endswith(".zip"):
        subprocess.run(["unzip", "-q", src_path, "-d", out_dir], check=True)
    elif lower.endswith((".tar.gz", ".tgz")):
        subprocess.run(["tar", "-xzf", src_path, "-C", out_dir], check=True)
    elif lower.endswith((".tar.xz", ".txz")):
        subprocess.run(["tar", "-xJf", src_path, "-C", out_dir], check=True)
    elif lower.endswith(".rar"):
        subprocess.run(["unrar", "x", "-o+", src_path, f"{out_dir}/"], check=True)
    elif lower.endswith((".7z", ".exe")):
        subprocess.run(["7z", "x", src_path, f"-o{out_dir}"], check=True)
    else:
        shutil.copy(src_path, os.path.join(out_dir, filename))

    return work_dir, out_dir


def list_extracted_files(base_dir):
    files = []
    for root, _, filenames in os.walk(base_dir):
        for fn in filenames:
            files.append(os.path.relpath(os.path.join(root, fn), base_dir))
    return sorted(files)


def nar_sha256(path):
    res = subprocess.run(["nix-hash", "--type", "sha256", "--base32", path], capture_output=True, text=True, check=True)
    base32_hash = res.stdout.strip()
    res2 = subprocess.run(["nix", "hash", "to-sri", "--type", "sha256", base32_hash], capture_output=True, text=True, check=True)
    return res2.stdout.strip()


def add_dir_to_nix_store(path):
    res = subprocess.run(["nix-store", "--add-fixed", "--recursive", "sha256", path], capture_output=True, text=True, check=True)
    return res.stdout.strip()


def process_itch(name, url, previous_sources, system=None):
    old = previous_sources.get(name)

    print(f"Checking [itch] {name} from {url}...")
    version = get_itch_metadata(url)

    if version is not None and old and old.get("url") == url and old.get("version") == version:
        print(f"  -> {name} unchanged (upload metadata matches); reusing cached hash, no download needed.")
        return old

    data, filename = fetch_itch_asset(name, url, system)

    if version is None:
        version = filename 
        if old and old.get("url") == url and old.get("version") == version:
            print(f"  -> {name} unchanged (filename matches); reusing cached hash.")
            return old

    print(f"  -> Rebuilding {name}'s output the way fetchItch does, to hash and seed the store...")
    game_slug = os.path.basename(url.rstrip('/'))

    work_dir, out_dir = replicate_fetchitch_output(data, filename, game_slug)
    try:
        files = list_extracted_files(out_dir)
        archive_content = scan_archive_contents_from_dir(out_dir)
        h = nar_sha256(out_dir)
        store_path = add_dir_to_nix_store(out_dir)
        print(f"  -> Seeded {store_path}; `nix build` will reuse it instead of re-fetching and re-extracting.")
    finally:
        shutil.rmtree(work_dir, ignore_errors=True)

    result = {
        "type": "itch",
        "url": url,
        "hash": h,
        "version": version,
        "files": files,
    }
    if archive_content:
        result["archiveContent"] = archive_content
    if system:
        result["platform"] = system
    return result

def http_get(url, headers=None):
    """Downloads a url using urllib, falling back to system curl if blocked by TLS fingerprinting."""
    all_headers = {'User-Agent': USER_AGENT, **(headers or {})}
    try:
        req = urllib.request.Request(url, headers=all_headers)
        with urllib.request.urlopen(req) as response:
            return response.read()
    except urllib.error.HTTPError as e:
        if e.code == 403:
            # Fallback to system curl to bypass Python socket TLS/JA3 fingerprint rejections
            cmd = ["curl", "-sL"]
            for k, v in all_headers.items():
                cmd += ["-H", f"{k}: {v}"]
            cmd.append(url)
            res = subprocess.run(cmd, capture_output=True, check=True)
            return res.stdout
        raise


def download_file(url):
    return http_get(url)


def nix_build_expr(fetch_call, extra_args):
    args_str = "".join(f'    {k} = {v};\n' for k, v in extra_args.items())
    # `hash` is a separate let-binding (rather than an argument to fetch_call)
    # purely so extract_hash_from_nix_build's `hash = "..."` regex can find a
    # placeholder to detect the hash type; our fetchers all take `sha256`, not
    # `hash`, as their actual argument name.
    return (
        f"let\n"
        f"  pkgs = import <nixpkgs> {{}};\n"
        f"  customLib = import ./lib {{\n"
        f"    inherit pkgs;\n"
        f"    inherit (pkgs) lib system;\n"
        f"    mkOutOfStoreSymlink = _x: {{}};\n"
        f"    config = {{}};\n"
        f"  }};\n"
        f'  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";\n'
        f"in\n"
        f"  customLib.{fetch_call} {{\n"
        f"{args_str}"
        f"    sha256 = hash;\n"
        f"  }}"
    )


def realize_build_output(fetch_call, extra_args, real_hash):
    """Given the same fetch_call/extra_args shape nix_build_expr takes, plus
    an already-known-good hash, actually builds it (not just hashes it) so
    its real content can be inspected. --builders '' forces a local build:
    the remote builder has shown flaky failures on real game-sized outputs
    during manual testing, unrelated to the derivation's own correctness."""
    args_str = "".join(f'    {k} = {v};\n' for k, v in extra_args.items())
    nix_expr = (
        f"let\n"
        f"  pkgs = import <nixpkgs> {{}};\n"
        f"  customLib = import ./lib {{\n"
        f"    inherit pkgs;\n"
        f"    inherit (pkgs) lib system;\n"
        f"    mkOutOfStoreSymlink = _x: {{}};\n"
        f"    config = {{}};\n"
        f"  }};\n"
        f"in\n"
        f"  customLib.{fetch_call} {{\n"
        f"{args_str}"
        f'    sha256 = "{real_hash}";\n'
        f"  }}"
    )
    res = subprocess.run(
        ["nix", "build", "--impure", "--builders", "", "--no-link", "--print-out-paths", "--expr", nix_expr],
        capture_output=True, text=True, check=True,
    )
    return res.stdout.strip().splitlines()[-1]


def scan_realized_output(store_path, single_file_name=None):
    """Lists files/archiveContent for a realized build output -- a directory
    for extract=true fetches, or a single file (itself possibly a pk3/ipk3)
    for a raw fetch. single_file_name is the fetcher's declared logical
    name (e.g. "LegendOfDoom.pk3"), used to key archiveContent in the single-
    file case -- NOT the realized store path's basename, which is prefixed
    with its content hash (/nix/store/<hash>-LegendOfDoom.pk3) and would
    never match the plain name Nix-side code (pk3.name) looks up by."""
    if os.path.isdir(store_path):
        return list_extracted_files(store_path), scan_archive_contents_from_dir(store_path)

    archive_content = {}
    name = single_file_name or os.path.basename(store_path)
    if name.lower().endswith(PK3_EXTENSIONS):
        with open(store_path, "rb") as f:
            contents = scan_archive_contents_bytes(f.read())
        if contents is not None:
            archive_content[name] = contents
    return [], archive_content


def parse_source_spec(raw):
    """'primary;key=value;flag' -> (primary, {"key": "value", "flag": True})
    -- a minimal extension to this file's plain key="value" TOML shape for
    sources (gdrive, mostly) that need an extra parameter or two (a custom
    output name, whether to extract) alongside their main identifier."""
    parts = raw.split(";")
    extra = {}
    for p in parts[1:]:
        if "=" in p:
            k, v = p.split("=", 1)
            extra[k.strip()] = v.strip()
        else:
            extra[p.strip()] = True
    return parts[0], extra


def process_nexus(name, target, previous_sources):
    old = previous_sources.get(name)
    game, mod_id = target.split('/', 1)

    print(f"Checking [nexus] {name} ({target})...")
    api_key = os.environ.get("NEXUS_API_KEY")
    if not api_key:
        raise RuntimeError(
            "NEXUS_API_KEY is not set. Get a Premium API key at "
            "https://next.nexusmods.com/settings/api-keys (unattended downloads require Premium)."
        )

    files = json.loads(http_get(
        f"https://api.nexusmods.com/v1/games/{game}/mods/{mod_id}/files.json?category=main,update",
        headers={"apikey": api_key},
    ))["files"]
    if not files:
        raise ValueError(f"No files found for nexus mod {target}")

    latest = max(files, key=lambda f: f["uploaded_timestamp"])
    file_id = latest["file_id"]
    version = f"{file_id}:{latest['uploaded_timestamp']}"

    if old and old.get("game") == game and str(old.get("modId")) == str(mod_id) and old.get("version") == version:
        print(f"  -> {name} unchanged (latest file matches); reusing cached hash.")
        return old

    print(f"  -> Fetching hash for {name} via Nix build...")
    nix_expr = nix_build_expr("fetchNexus", {
        "game": f'"{game}"',
        "modId": mod_id,
        "fileId": file_id,
    })
    h = extract_hash_from_nix_build(nix_expr, f"fetchNexus ({name})")

    return {
        "type": "nexus",
        "game": game,
        "modId": mod_id,
        "fileId": file_id,
        "version": version,
        "hash": h,
    }


def process_curseforge(name, mod_id, previous_sources):
    old = previous_sources.get(name)

    print(f"Checking [curseforge] {name} (mod {mod_id})...")
    api_key = os.environ.get("CURSEFORGE_API_KEY")
    if not api_key:
        raise RuntimeError(
            "CURSEFORGE_API_KEY is not set. Apply for a key at "
            "https://support.curseforge.com/support/solutions/articles/9000208346."
        )

    files = json.loads(http_get(
        f"https://api.curseforge.com/v1/mods/{mod_id}/files",
        headers={"x-api-key": api_key},
    ))["data"]
    if not files:
        raise ValueError(f"No files found for curseforge mod {mod_id}")

    latest = max(files, key=lambda f: f["fileDate"])
    file_id = latest["id"]
    version = f"{file_id}:{latest['fileDate']}"

    if old and str(old.get("modId")) == str(mod_id) and old.get("version") == version:
        print(f"  -> {name} unchanged (latest file matches); reusing cached hash.")
        return old

    print(f"  -> Fetching hash for {name} via Nix build...")
    nix_expr = nix_build_expr("fetchCurseForge", {
        "modId": mod_id,
        "fileId": file_id,
    })
    h = extract_hash_from_nix_build(nix_expr, f"fetchCurseForge ({name})")

    return {
        "type": "curseforge",
        "modId": mod_id,
        "fileId": file_id,
        "version": version,
        "hash": h,
    }


def process_modrinth(name, project, previous_sources):
    old = previous_sources.get(name)

    print(f"Checking [modrinth] {name} (project {project})...")
    versions = json.loads(http_get(f"https://api.modrinth.com/v2/project/{project}/version"))
    if not versions:
        raise ValueError(f"No versions found for modrinth project {project}")

    latest = max(versions, key=lambda v: v["date_published"])
    version_id = latest["id"]
    version = f"{version_id}:{latest['date_published']}"

    if old and old.get("project") == project and old.get("version") == version:
        print(f"  -> {name} unchanged (latest version matches); reusing cached hash.")
        return old

    print(f"  -> Fetching hash for {name} via Nix build...")
    nix_expr = nix_build_expr("fetchModrinth", {
        "project": f'"{project}"',
        "versionId": f'"{version_id}"',
    })
    h = extract_hash_from_nix_build(nix_expr, f"fetchModrinth ({name})")

    return {
        "type": "modrinth",
        "project": project,
        "versionId": version_id,
        "version": version,
        "hash": h,
    }

# Same mirror list lib/fetchers/idgames.nix's fetchIdGames tries, in the
# same order; kept here too since get_idgames_mirror_version/
# download_idgames_archive need real HTTP access during `update-sources.py`
# runs, independent of the Nix build.
IDGAMES_MIRRORS = [
  "ftp.fu-berlin.de/pc/games/idgames",
  "youfailit.net/pub/idgames",
  "ftpmirror.infania.net/pub/idgames",
  "mirror.braindrainlan.nu/pub/idgames",
  "files.xvertigox.com/idgames",
  "lethe.chinstrap.org/idgames",
  "mirrors.lug.mtu.edu/idgames",
  "gamers.org/pub/idgames"
]


def get_idgames_mirror_version(filepath):
    """
    Queries an open idgames mirror directly, completely bypassing Doomworld's Cloudflare.
    """
    clean_path = filepath.lstrip('/')

    for mirror in IDGAMES_MIRRORS:
        url = f"https://{mirror}/{clean_path}"
        try:
            req = urllib.request.Request(url, method='HEAD', headers={'User-Agent': 'curl/7.88.1'})
            with urllib.request.urlopen(req, timeout=5) as resp:
                last_modified = resp.headers.get('Last-Modified')
                if last_modified:
                    return last_modified
        except Exception:
            continue

    raise RuntimeError(f"Could not reach mirrors for {filepath}")


def download_idgames_archive(filepath):
    """Downloads the real idgames zip (same mirror list/order as fetchIdGames) so its
    file list and any pk3/ipk3 members' contents can be recorded in sources.nix."""
    clean_path = filepath.lstrip('/')
    last_err = None
    for mirror in IDGAMES_MIRRORS:
        url = f"https://{mirror}/{clean_path}"
        try:
            return download_file(url)
        except Exception as e:
            last_err = e
            continue
    raise RuntimeError(f"Could not download {filepath} from any idgames mirror: {last_err}")

def process_idgames(name, game, previous_sources):
    old = previous_sources.get(name)

    print(f"Checking [idgames] {name} for {game}...")

    # Normalize to int if possible to align with lib.isInt evaluations in Nix
    if str(game).isdigit():
        game = int(game)
        
    is_id = isinstance(game, int)
    
    if is_id:
        raise "Due to the API using cloudflare, it is currently possible to support idgames by id"

    version = get_idgames_mirror_version(game)

    # Compare current metadata against cached sources, avoid Nix builds if unchanged
    if version and old and str(old.get("game")) == str(game) and old.get("version") == version:
        print(f"  -> {name} unchanged (release date matches); reusing cached hash.")
        return old

    print(f"  -> Fetching hash for {name} via Nix build...")

    game_val = str(game) if is_id else f'"{game}"'

    nix_expr = (
        f"let\n"
        f"  pkgs = import <nixpkgs> {{}};\n"
        f"  customLib = import ./lib {{\n"
        f"    inherit pkgs;\n"
        f"    inherit (pkgs) lib system;\n"
        f"    mkOutOfStoreSymlink = _x: {{}};\n"
        f"    config = {{}};\n"
        f"  }};\n"
        f"in\n"
        f"  customLib.fetchIdGames {{\n"
        f'    game = {game_val};\n'
        f'    version = "{version}";\n'
        f'    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";\n'
        f"  }}"
    )

    h = extract_hash_from_nix_build(nix_expr, f"fetchIdGames ({name})")

    print(f"  -> Downloading {name}'s archive to record its file list...")
    files = []
    archive_content = {}
    try:
        data = download_idgames_archive(game)
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            files = sorted(
                zip_member_path(info) for info in z.infolist()
                if not info.filename.endswith('/') and not info.is_dir()
            )
            archive_content = scan_archive_contents_from_zip(z)
    except Exception as e:
        print(f"  -> Warning: couldn't list {name}'s archive contents ({e}); sources.nix entry will have no 'files'.", file=sys.stderr)

    result = {
        "type": "idgames",
        "game": game,
        "version": version,
        "hash": h,
    }
    if files:
        result["files"] = files
    if archive_content:
        result["archiveContent"] = archive_content
    return result

NIX_BARE_IDENTIFIER_RE = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_'-]*$")


def to_nix_attr_name(k):
    """Most keys in this file (source names, field names) are valid bare Nix
    identifiers and are left unquoted to keep the diff/output readable; but
    archiveContent introduces literal filenames as keys (e.g. "Paranoid.pk3"),
    which need quoting since '.' isn't valid in a bare identifier."""
    if NIX_BARE_IDENTIFIER_RE.match(k):
        return k
    escaped = k.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def to_nix_val(val, indent_level=0):
    indent = "  " * indent_level
    if isinstance(val, bool):
        return "true" if val else "false"
    if isinstance(val, str):
        escaped = val.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    elif isinstance(val, list):
        if not val:
            return "[ ]"
        lines = []
        for item in val:
            lines.append(f"{indent}  {to_nix_val(item, indent_level + 1)}")
        return "[\n" + "\n".join(lines) + f"\n{indent}]"
    elif isinstance(val, dict):
        if not val:
            return "{ }"
        lines = []
        for k in sorted(val.keys()):
            lines.append(f"{indent}  {to_nix_attr_name(k)} = {to_nix_val(val[k], indent_level + 1)};")
        return "{\n" + "\n".join(lines) + f"\n{indent}}}"
    return str(val)


def main():
    append_mode = "--append" in sys.argv
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    toml_path, nix_path = "sources.toml", "sources.nix"
    if not os.path.exists(toml_path):
        print(f"Error: {toml_path} not found.", file=sys.stderr)
        sys.exit(1)
        
    with open(toml_path, "r") as f:
        toml_content = f.read()
    try:
        sources_data = parse_toml(toml_content)
    except Exception as e:
        print(f"Error parsing {toml_path}: {e}", file=sys.stderr)
        sys.exit(1)
        
    previous_sources = load_previous_nix(nix_path)
    results = dict(previous_sources) if append_mode else {}
    has_errors = False

    # Insert idgames into the designated priority fetching queue
    priority_sections = ["url", "zip", "git", "git-tag", "idgames"]
    custom_sections = [s for s in sources_data.keys() if s not in priority_sections and s not in ["go", "npm"]]
    ordered_sections = priority_sections + custom_sections + ["go", "npm"]
    
    for section in ordered_sections:
        if section not in sources_data:
            continue
        for name, target in sources_data[section].items():
            if append_mode and name in previous_sources:
                continue
            try:
                if section == "url":
                    results[name] = process_url(name, target)
                elif section == "zip":
                    results[name] = process_zip(name, target)
                elif section == "git-tag":
                    results[name] = process_git_tag(name, target)
                elif section == "git":
                    results[name] = process_git(name, target)
                elif section == "idgames":
                    results[name] = process_idgames(name, target, previous_sources)
                elif section == "go":
                    results[name] = process_go(name, target, results, previous_sources)
                elif section == "npm":
                    results[name] = process_npm(name, target, results, previous_sources)
                elif section.startswith("itch"):
                    system = section.split('-', 1)[1] if '-' in section else None
                    results[name] = process_itch(name, target, previous_sources, system)
                elif section == "nexus":
                    results[name] = process_nexus(name, target, previous_sources)
                elif section == "curseforge":
                    results[name] = process_curseforge(name, target, previous_sources)
                elif section == "modrinth":
                    results[name] = process_modrinth(name, target, previous_sources)
                elif section == "gdrive":
                    results[name] = process_gdrive(name, target, previous_sources)
                elif section == "mediafire":
                    results[name] = process_mediafire(name, target, previous_sources)
                elif section == "moddb":
                    results[name] = process_moddb(name, target, previous_sources)
                else:
                    results[name] = process_custom(section, name, target)
            except Exception as e:
                print(f"Error updating {name} under [{section}]: {e}", file=sys.stderr)
                has_errors = True
                
    if has_errors:
        print("Update completed with errors. sources.nix was not updated.", file=sys.stderr)
        sys.exit(1)
        
    nested_results = {}
    for flat_key, info in results.items():
        parts = flat_key.split('.')
        curr = nested_results
        for part in parts[:-1]:
            curr = curr.setdefault(part, {})
        curr[parts[-1]] = info

    with open(nix_path, "w") as f:
        f.write(f"# This file is autogenerated by update-sources.py. Do not edit!\n{to_nix_val(nested_results, 0)}\n")
    print(f"Successfully updated {nix_path}")


if __name__ == "__main__":
    main()