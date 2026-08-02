# Lossless OBJ/MTL minification: drops "#" comment lines and blank lines,
# and trims trailing zeros from decimal number tokens (e.g. "2.500000" ->
# "2.5") as pure text -- never re-parses a number, so there's no float
# round-tripping/precision risk (unlike gameoptimizer's objmin.js, which
# gets the same trailing-zero trim as a side effect of a real
# parseFloat/toString round-trip). Integers (no ".") and anything else are
# left untouched.
/^#/ { next }
/^[ \t]*$/ { next }
{
  for (i = 1; i <= NF; i++) {
    if ($i ~ /^-?[0-9]+\.[0-9]+$/) {
      t = $i
      sub(/0+$/, "", t)
      sub(/\.$/, "", t)
      $i = t
    }
  }
  print
}
