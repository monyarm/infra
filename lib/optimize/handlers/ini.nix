{
  lineCommentsFilter,
  blankLinesFilter,
  pipeFilters,
  ...
}:
# INI comments are ";" (not "#" too -- a bare "key=#RRGGBB" color line
# would otherwise be misread as a full-line comment).
let
  handler =
    src:
    pipeFilters [
      (lineCommentsFilter { prefixes = [ ";" ]; })
      (blankLinesFilter { })
    ] src;
in
{
  inherit handler;
  extensions = [ "ini" ];
}
