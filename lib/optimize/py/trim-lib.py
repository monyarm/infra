#!/usr/bin/env python3
"""Crude Nix source tree-shaker, invoked from dynamic.nix's optimizeLibPath.

Keeps only the top-level `rec {}` bindings in a set of "lib" files that are
(transitively) referenced -- starting from every lib/optimize/*.nix
handler's own destructured param names -- discarding the rest, so an edit to
an unused binding elsewhere in lib/misc.nix, lib/strings.nix, etc. doesn't
invalidate every archive's cached optimize-instantiate step. Also trims each
file's own param list down to what its surviving bindings actually
reference (plus lib/pkgs if it originally took them), so one trimmed file
never ends up requiring a name another trimmed file no longer exports.

Not a real parser -- just a string/comment-aware brace and let/in scanner --
but biased to over-include on anything ambiguous (e.g. an identifier-looking
substring inside a string literal), so a scanning mistake can only keep too
much, never drop something needed.

Usage: trim-lib.py LIB_DIR OPTIMIZE_DIR OUT_DIR FILE1,FILE2,...
  LIB_DIR: directory containing the target files (FILE1, FILE2, ...)
  OPTIMIZE_DIR: directory walked for root names (every *.nix file's own
    first `{...}:` param block)
  OUT_DIR: where trimmed copies of each target file get written

Second mode -- Usage: trim-lib.py --strip-tree SRC_DIR OUT_DIR
  Comment/blank-line-strips (not dead-code-eliminates) every *.nix file
  under SRC_DIR, mirroring its subdirectory layout into OUT_DIR. Unlike the
  mode above, this covers the *whole* lib/optimize/ subtree (dynamic.nix,
  dynamic-inner.nix, every handlers/*.nix, ...), which -- being handler
  files auto-discovered by lib/mkFormatDispatch.nix rather than statically
  referenced by name -- isn't safe to run the binding-level tree-shake on.
  Comment-stripping alone is enough to stop doc-only edits (this repo's
  handlers carry heavy header comments) from perturbing optimizeLibPath's
  hash and forcing a full re-nix-instantiate for no real reason. Non-.nix
  files are skipped entirely -- the caller copies those through verbatim.
"""

import re
import sys


def skip_string_or_comment(text, i):
    """If text[i:] starts a string literal or comment, return the index just
    past its end. Otherwise return None."""
    n = len(text)
    if text.startswith("#", i):
        j = text.find("\n", i)
        return n if j == -1 else j + 1
    if text.startswith("/*", i):
        j = text.find("*/", i + 2)
        return n if j == -1 else j + 2
    if text.startswith("''", i):
        j = i + 2
        while j < n:
            if text.startswith("''${", j):
                # ''${ isn't an interpolation start, it's an escaped ${ -- skip literally.
                j += 4
                continue
            if text.startswith("${", j):
                j = skip_balanced(text, j + 2, "{", "}")
                continue
            if text.startswith("'''", j):
                j += 3
                continue
            if text.startswith("''", j):
                return j + 2
            j += 1
        return n
    if text.startswith('"', i):
        j = i + 1
        while j < n:
            if text[j] == "\\":
                j += 2
                continue
            if text.startswith("${", j):
                j = skip_balanced(text, j + 2, "{", "}")
                continue
            if text[j] == '"':
                return j + 1
            j += 1
        return n
    return None


def skip_balanced(text, i, open_ch, close_ch):
    """i points just after an opening bracket already consumed; returns the
    index just past the matching close bracket, skipping strings/comments."""
    depth = 1
    n = len(text)
    while i < n and depth > 0:
        skipped = skip_string_or_comment(text, i)
        if skipped is not None:
            i = skipped
            continue
        c = text[i]
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
        i += 1
    return i


def find_matching(text, open_idx):
    """open_idx points AT an opening bracket char; returns index just past
    its matching close bracket."""
    ch = text[open_idx]
    close = {"{": "}", "(": ")", "[": "]"}[ch]
    return skip_balanced(text, open_idx + 1, ch, close)


# NOTE: `with EXPR; BODY` has the exact same ambiguous-';' problem as
# `let ... in` but isn't handled below (only checked, not fixed) -- none of
# lib/{misc,strings,constants,files}.nix use `with` today (verified via
# grep; the only two "with" matches are inside comments). If one is ever
# added, this scanner would truncate that binding early -- same failure
# mode as the let/in bug this function exists to fix, just unguarded.
KEYWORD_RE = re.compile(r"\b(let|in)\b")


def find_expr_end(text, i):
    """i points just after the '=' of a binding; returns the index of the
    terminating top-level ';' for this binding's value expression.

    Brackets ({([) are skipped as balanced units. `let name = ...; in body`
    doesn't use brackets to delimit its own scope, so a naive "next
    unbracketed ;" search stops at the first internal ; inside it -- tracked
    here via a depth counter: every `let` increments it, every `in`
    decrements it (multiple bindings inside one `let` share the same
    increment, only closed by that let's own `in`). A `;` only terminates
    the binding when both bracket depth and this counter are 0.
    """
    n = len(text)
    let_depth = 0
    k = i
    while k < n:
        skipped = skip_string_or_comment(text, k)
        if skipped is not None:
            k = skipped
            continue
        c = text[k]
        if c in "{([":
            k = find_matching(text, k)
            continue
        m = KEYWORD_RE.match(text, k)
        if m:
            if m.group(1) == "let":
                let_depth += 1
            else:  # "in"
                let_depth = max(0, let_depth - 1)
            k = m.end()
            continue
        if c == ";":
            if let_depth == 0:
                return k
            k += 1
            continue
        k += 1
    return n


IDENT = r"[A-Za-z_][A-Za-z0-9_'-]*"


def extract_param_names(text, exclude_lib_pkgs=True):
    """First `{...}:` in the file (skipping comments) -> set of identifier
    names in the pattern (drops `?  default`, `...`, and any `@name` alias
    is added too). exclude_lib_pkgs=True is for root-name extraction (lib/
    pkgs are always supplied directly, not something to look for among our 4
    files); False is for trimming a file's own param list, which needs the
    full set including lib/pkgs so callers can always keep those two."""
    i = 0
    n = len(text)
    while i < n:
        skipped = skip_string_or_comment(text, i)
        if skipped is not None:
            i = skipped
            continue
        if text[i] == "{":
            end = find_matching(text, i)
            inner = text[i + 1 : end - 1]
            names = set(re.findall(IDENT, inner))
            if exclude_lib_pkgs:
                names -= {"lib", "pkgs"}
            return names
        if text[i].isspace():
            i += 1
            continue
        # Anything else before the first '{' (e.g. a bare identifier arg) --
        # give up gracefully, no destructured params to find.
        return set()
    return set()


def extract_top_level_bindings(text):
    """Returns (pre_text, bindings, post_text) where pre_text is everything
    up to and including the outer `rec {`/`{` opener, bindings is a dict of
    name -> full "name = expr;" text, and post_text is the closing `}` plus
    anything after."""
    # Find the first `{` or `rec {` after the leading `{...}:` param block.
    i = 0
    n = len(text)
    depth0_brace = None
    # Skip the param block itself first.
    while i < n:
        skipped = skip_string_or_comment(text, i)
        if skipped is not None:
            i = skipped
            continue
        if text[i] == "{":
            i = find_matching(text, i)
            break
        i += 1
    # Now find the `:` then the (optional `rec`) `{` that opens the body.
    while i < n:
        skipped = skip_string_or_comment(text, i)
        if skipped is not None:
            i = skipped
            continue
        if text[i] == "{":
            depth0_brace = i
            break
        i += 1
    if depth0_brace is None:
        raise ValueError("could not find body '{' ")

    body_start = depth0_brace + 1
    body_end = find_matching(text, depth0_brace) - 1  # index of the matching '}'
    pre_text = text[:body_start]
    post_text = text[body_end:]
    body = text[body_start:body_end]

    bindings = {}
    i = 0
    n = len(body)
    while i < n:
        skipped = skip_string_or_comment(body, i)
        if skipped is not None:
            i = skipped
            continue
        if body[i].isspace() or body[i] == ";":
            i += 1
            continue
        m = re.match(IDENT, body[i:])
        if not m:
            i += 1
            continue
        name_start = i
        name = m.group(0)
        j = i + len(name)
        while j < n and body[j].isspace():
            j += 1
        if j < n and body[j] == "=":
            semi = find_expr_end(body, j + 1)
            k = min(semi + 1, n)
            bindings[name] = body[name_start:k]
            i = k
        else:
            i = name_start + len(name)
    return pre_text, bindings, post_text


def _strip_interpolation_body(text, open_at, out):
    """open_at points at the '$' of a '${' already detected. Blanks the
    '${'/'}' delimiters but recursively keeps the interpolation's own
    content visible to the reference scan (it's real Nix code, e.g. the
    `getName` in `"${getName folderDrv}-deref"` is a genuine reference,
    not string data) -- including any strings/comments nested inside it.
    Returns the index just past the matching '}'."""
    close = skip_balanced(text, open_at + 2, "{", "}")
    inner_start = open_at + 2
    inner_end = close - 1
    out.append("  ")
    out.append(strip_strings_and_comments(text[inner_start:inner_end]))
    out.append(" ")
    return close


def _strip_double_string(text, i, out):
    """i points at the opening '\"'. Blanks the literal text, preserving
    interpolations (see _strip_interpolation_body). Returns index just
    past the closing '\"'."""
    n = len(text)
    out.append(" ")
    j = i + 1
    while j < n:
        if text[j] == "\\":
            out.append("  ")
            j += 2
            continue
        if text.startswith("${", j):
            j = _strip_interpolation_body(text, j, out)
            continue
        if text[j] == '"':
            out.append(" ")
            return j + 1
        out.append(" ")
        j += 1
    return n


def _strip_indented_string(text, i, out):
    """i points at the opening \"''\". Blanks the literal text, preserving
    interpolations (see _strip_interpolation_body). Returns index just
    past the closing \"''\"."""
    n = len(text)
    out.append("  ")
    j = i + 2
    while j < n:
        if text.startswith("''${", j):
            out.append("    ")
            j += 4
            continue
        if text.startswith("${", j):
            j = _strip_interpolation_body(text, j, out)
            continue
        if text.startswith("'''", j):
            out.append("   ")
            j += 3
            continue
        if text.startswith("''", j):
            out.append("  ")
            return j + 2
        out.append(" ")
        j += 1
    return n


def strip_strings_and_comments(text):
    """For reference-scanning only: replace every string/comment span with
    spaces (preserving length, not that it matters here) so an
    identifier-looking substring inside a string literal or comment (e.g. a
    throw message that happens to start with a binding's name) can't be
    mistaken for a real code reference -- EXCEPT a string's own `${...}`
    interpolations, which are real Nix expressions (not string data) and
    must stay visible, recursively, or a binding referenced only inside one
    (e.g. `pkgs.runCommand "${getName folderDrv}-deref"`) would look
    unreferenced and get trimmed away. Not used for binding extraction --
    only this narrower scan needs this precision; extraction already only
    ever over-includes, which is safe."""
    out = []
    i = 0
    n = len(text)
    while i < n:
        if text.startswith("#", i) or text.startswith("/*", i):
            skipped = skip_string_or_comment(text, i)
            out.append(" " * (skipped - i))
            i = skipped
            continue
        if text.startswith("''", i):
            i = _strip_indented_string(text, i, out)
            continue
        if text.startswith('"', i):
            i = _strip_double_string(text, i, out)
            continue
        out.append(text[i])
        i += 1
    return "".join(out)


def strip_comments_for_output(text):
    """For the final emitted file only: drop `#`/`/* */` comments entirely
    (string literals are left byte-for-byte untouched -- only an actual
    comment start, checked before falling back to the generic string-or-
    comment skip, gets dropped). A line comment's own trailing newline is
    kept so it doesn't glue the next line onto whatever preceded it."""
    out = []
    i = 0
    n = len(text)
    while i < n:
        if text.startswith("#", i):
            skipped = skip_string_or_comment(text, i)
            if skipped > i and text[skipped - 1] == "\n":
                out.append("\n")
            i = skipped
            continue
        if text.startswith("/*", i):
            i = skip_string_or_comment(text, i)
            continue
        skipped = skip_string_or_comment(text, i)  # a string -- keep verbatim
        if skipped is not None:
            out.append(text[i:skipped])
            i = skipped
            continue
        out.append(text[i])
        i += 1
    return "".join(out)


def strip_blank_lines(text):
    return "\n".join(line for line in text.split("\n") if line.strip() != "")


def references(expr_text, candidate_names):
    found = set(re.findall(IDENT, strip_strings_and_comments(expr_text)))
    return found & candidate_names


def strip_tree(src_dir, out_dir):
    import os

    for root, _dirs, names in os.walk(src_dir):
        for fn in names:
            if not fn.endswith(".nix"):
                continue
            src_path = os.path.join(root, fn)
            rel = os.path.relpath(src_path, src_dir)
            out_path = os.path.join(out_dir, rel)
            os.makedirs(os.path.dirname(out_path), exist_ok=True)
            with open(src_path) as f:
                text = f.read()
            stripped = strip_blank_lines(strip_comments_for_output(text))
            # rstrip: a comment-only edit that adds/removes trailing blank
            # lines must not change the stripped bytes, or it would still
            # invalidate optimizeLibPath's CA hash (defeats the whole point
            # of comment-stripping).
            with open(out_path, "w") as f:
                f.write(stripped.rstrip() + "\n")


def main():
    if sys.argv[1:2] == ["--strip-tree"]:
        src_dir, out_dir = sys.argv[2:4]
        strip_tree(src_dir, out_dir)
        return

    lib_dir, optimize_dir, out_dir, files_csv = sys.argv[1:5]
    import os

    files = files_csv.split(",")

    # 1. Root names: every optimize/*.nix file's own param-list identifiers.
    roots = set()
    for root, _dirs, names in os.walk(optimize_dir):
        for fn in names:
            if fn.endswith(".nix"):
                with open(os.path.join(root, fn)) as f:
                    roots |= extract_param_names(f.read())

    # 2. Parse each target file's own param names + top-level bindings.
    parsed = {}
    for fn in files:
        with open(os.path.join(lib_dir, fn)) as f:
            text = f.read()
        own_params = extract_param_names(text, exclude_lib_pkgs=False)
        _pre, bindings, post = extract_top_level_bindings(text)
        parsed[fn] = (own_params, bindings, post)

    all_names = set()
    for _params, bindings, _post in parsed.values():
        all_names |= set(bindings.keys())

    # 2b. dynamic-inner.nix (the only thing actually run through
    # recursive-nix, and thus the only file that needs optimizeLibPath's
    # contents at all -- dynamic.nix itself just passes the path string
    # through to nix-instantiate, verified via grep, never dereferences it)
    # doesn't consume misc/strings/files.nix through a curated commonArgs
    # param list like regular handlers do -- it imports those files
    # directly and reference exports by attribute (e.g. `misc.parallel`,
    # `inherit (strings) sanitizeName`). A handler's own param-list scan
    # above can't see that, so scan its full body as an extra root source,
    # or a direct reference added there (not already reachable transitively
    # from a handler root) would get silently trimmed away.
    innerPath = os.path.join(optimize_dir, "dynamic-inner.nix")
    if os.path.exists(innerPath):
        with open(innerPath) as f:
            roots |= references(f.read(), all_names)

    # 3. Transitive closure starting from roots that exist in these files.
    keep = set()
    frontier = roots & all_names
    while frontier:
        keep |= frontier
        next_frontier = set()
        for _params, bindings, _post in parsed.values():
            for name in frontier:
                expr = bindings.get(name)
                if expr is None:
                    continue
                refs = references(expr, all_names)
                next_frontier |= refs - keep
        frontier = next_frontier

    # 4. Per file, trim its own param list down to lib/pkgs (always kept --
    # structural, near-universal) plus whatever its surviving bindings'
    # bodies actually reference -- otherwise a kept binding in file A could
    # require a param (e.g. `parallel`) that file B's own trimming already
    # dropped from what it exports, breaking the `// misc // strings` spread
    # that wires the reconstructed files together.
    os.makedirs(out_dir, exist_ok=True)
    summary = []
    for fn, (own_params, bindings, post) in parsed.items():
        kept_names = [name for name in bindings if name in keep]
        body = "\n".join(bindings[name] for name in kept_names)
        used_params = set()
        for name in kept_names:
            used_params |= references(bindings[name], own_params)
        # lib/pkgs only if THIS file originally declared them -- callers
        # supply exactly what each file's own (untrimmed) signature asked
        # for, e.g. constants.nix only ever took `lib`, never `pkgs`.
        kept_params = used_params | (own_params & {"lib", "pkgs"})
        param_lines = "".join(f"  {p},\n" for p in sorted(kept_params))
        pre = "{\n" + param_lines + "  ...\n}:\nrec {\n"
        full = strip_blank_lines(strip_comments_for_output(pre + body + "\n" + post))
        with open(os.path.join(out_dir, fn), "w") as f:
            f.write(full + "\n")
        summary.append(
            f"{fn}: kept {len(kept_names)}/{len(bindings)} bindings -> {sorted(kept_names)}; "
            f"params -> {sorted(kept_params)}"
        )

    print("\n".join(summary), file=sys.stderr)


if __name__ == "__main__":
    main()
