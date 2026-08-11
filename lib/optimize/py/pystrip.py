#!/usr/bin/env python3
"""Drops '#' comment tokens and blank lines from Python source, leaving
every STRING token (docstrings, f-strings, anything containing '#')
completely untouched -- it operates on the real tokenizer's output, not a
line-based regex, so a '#' inside a string is never mistaken for a comment.
Reassembles with tokenize.untokenize's simple 2-tuple (type, string) form:
verified this avoids the backslash-continuation artifacts the full 5-tuple
(type, string, start, end, line) form produces when tokens are dropped.
Exits nonzero (writing nothing) if the input doesn't tokenize as valid
Python, or if the stripped output doesn't re-tokenize cleanly -- either way
the caller falls back to passthrough.
"""
import io
import sys
import tokenize


def strip(src: str) -> str:
    out = []
    for tok in tokenize.generate_tokens(io.StringIO(src).readline):
        tok_type, tok_string = tok[0], tok[1]
        if tok_type == tokenize.COMMENT:
            continue
        if tok_type == tokenize.NL and tok_string.strip() == "":
            continue
        out.append((tok_type, tok_string))
    return tokenize.untokenize(out)


src, dest = sys.argv[1], sys.argv[2]
text = open(src).read()
stripped = strip(text)
# Round-trip check: re-tokenizing the result must not raise -- a stripped
# file that's no longer valid Python is worse than not stripping at all.
list(tokenize.generate_tokens(io.StringIO(stripped).readline))
with open(dest, "w") as f:
    f.write(stripped)
