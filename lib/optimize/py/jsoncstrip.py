#!/usr/bin/env python3
"""Strips '//' and '/* */' comments from JSON-with-comments, regardless of
its actual extension (.json/.jsonc alike -- jq itself can't parse either
with comments still in). String-literal-aware (tracks '"'/'\\' escape
state) so a comment-looking sequence inside a string value is left alone --
verified against minijson's own adversarial test fixtures (escaped quotes/
backslashes sitting directly next to '//'/'/* */'-looking sequences).
Output is still JSON, not further minified -- the caller pipes it through
jq -c for that.
"""
import sys


def strip_jsonc(text: str) -> str:
    out = []
    i, n = 0, len(text)
    in_string = False
    escape = False
    while i < n:
        c = text[i]
        if in_string:
            out.append(c)
            if escape:
                escape = False
            elif c == "\\":
                escape = True
            elif c == '"':
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            j = text.find("\n", i)
            i = n if j == -1 else j
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            j = text.find("*/", i + 2)
            i = n if j == -1 else j + 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


src, dest = sys.argv[1], sys.argv[2]
with open(dest, "w") as f:
    f.write(strip_jsonc(open(src).read()))
