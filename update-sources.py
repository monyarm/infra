#!/usr/bin/env python3
import base64
import hashlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from urllib.parse import urlparse

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0"


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
                if isinstance(v, dict) and "type" not in v:
                    flatten(v, key)
                else:
                    flat[key] = v
                    
        flatten(nested)
        return flat
    except Exception as e:
        print(f"Warning: Could not parse old {nix_path} ({e}). Performing full calculation.", file=sys.stderr)
        return {}


def download_file(url):
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    with urllib.request.urlopen(req) as response:
        return response.read()


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
                files.append(info.filename)
                
    files.sort()
    return {
        "type": "zip",
        "url": url,
        "hash": h,
        "files": files
    }


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
        # Match your environment's custom fetcher convention
        return f'customLib.fetchGitTree {{ url = "{info["url"]}"; rev = "{info["rev"]}"; hash = "{info["hash"]}"; date = "{info["date"]}"; }}'
    elif t == "zip":
        return f'pkgs.fetchzip {{ url = "{info["url"]}"; hash = "{info["hash"]}"; }}'
    elif t == "url":
        return f'pkgs.fetchurl {{ url = "{info["url"]}"; hash = "{info["hash"]}"; }}'
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
    
    # We must construct a clean environment that brings in customLib to evaluate make_nix_src_expr
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


def to_nix_val(val, indent_level=0):
    indent = "  " * indent_level
    if isinstance(val, str):
        escaped = val.replace("\\\\", "\\\\\\\\").replace("\"", "\\\"")
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
            lines.append(f"{indent}  {k} = {to_nix_val(val[k], indent_level + 1)};")
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

    priority_sections = ["url", "zip", "git", "git-tag"]
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
                elif section == "go":
                    results[name] = process_go(name, target, results, previous_sources)
                elif section == "npm":
                    results[name] = process_npm(name, target, results, previous_sources)
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