# Strips one or more block-comment styles (e.g. C's /* */), matched
# anywhere -- including mid-line and across newlines -- like real block
# comments. Multiple pairs are supported: for each position, whichever
# configured start delimiter occurs earliest wins.
#
# Invocation: gawk -v pairs="start1\tend1\nstart2\tend2" -f block-comments.awk
BEGIN {
  npairs = split(pairs, entries, "\n")
  for (i = 1; i <= npairs; i++) {
    split(entries[i], kv, "\t")
    starts[i] = kv[1]
    ends[i] = kv[2]
  }
  in_comment = 0
}
{
  line = $0
  result = ""
  while (length(line) > 0) {
    if (in_comment) {
      idx = index(line, cur_end)
      if (idx == 0) {
        line = ""
      } else {
        line = substr(line, idx + length(cur_end))
        in_comment = 0
      }
    } else {
      best_idx = 0
      best_pair = 0
      for (i = 1; i <= npairs; i++) {
        idx = index(line, starts[i])
        if (idx > 0 && (best_idx == 0 || idx < best_idx)) {
          best_idx = idx
          best_pair = i
        }
      }
      if (best_idx == 0) {
        result = result line
        line = ""
      } else {
        result = result substr(line, 1, best_idx - 1)
        line = substr(line, best_idx + length(starts[best_pair]))
        cur_end = ends[best_pair]
        in_comment = 1
      }
    }
  }
  if (in_comment) {
    # withhold the newline, comment continues on the next line
    printf "%s", result
  } else {
    print result
  }
}
