{
  blockCommentsFilter,
  blankLinesFilter,
  pipeFilters,
  ...
}:
# Apache FreeMarker Template Language (the ".ftl" extension gameoptimizer
# handles is this, not the game). Its "<#-- -->" comments and "<#if>"-style
# directive tags aren't valid XML ("#" isn't a legal XML name-start
# character), so routing this through the xml.nix/xmllint path is a dead
# end -- real FTL content just fails to parse there. Comment-stripping
# only; the whitespace-collapse gameoptimizer's ftlmin.js also does needs
# real HTML-minification machinery, out of scope here (deferred with
# html/js).
let
  handler =
    src:
    pipeFilters [
      (blockCommentsFilter {
        pairs = [
          {
            start = "<#--";
            end = "-->";
          }
        ];
      })
      (blankLinesFilter { })
    ] src;
in
{
  inherit handler;
  extensions = [ "ftl" ];
}
