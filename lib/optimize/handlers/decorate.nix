{
  lib,
  lineCommentsFilter,
  blankLinesFilter,
  pipeFilters,
  ...
}:
# GZDoom directive text lumps (DECORATE, DECALDEF, DECLOLD, SNDINFO,
# MAPINFO, etc., including their dot-suffixed variants like
# "DECORATE.ChexMonsters"): plain line-oriented text, "//" line comments,
# no length-prefixed blocks like DeHackEd's Text sections -- no
# protectAfter needed (verified against real DECALDEF/DECLOLD/SNDINFO/
# DECORATE.* content).
let
  gzdoomLumpPrefixes = [
    "decorate"
    "decaldef"
    "declold"
    "sndinfo"
    "mapinfo"
    "gldefs"
    "animdefs"
    "cvarinfo"
    "language"
    "loadacs"
    "menudef"
    "gameinfo"
    "iwadinfo"
    "keyconf"
    "sbarinfo"
    "voxeldef"
    "trnslate"
    "fontdefs"
    "lockdefs"
    "modeldef"
    "textcolo"
    "sndseq"
    "terrain"
    "reverbs"
    "dec_"
    "textures"
    "zscript"
    "zmapinfo"
  ];
  handler =
    src:
    pipeFilters [
      (lineCommentsFilter { prefixes = [ "//" ]; })
      (blankLinesFilter { })
    ] src;
in
{
  inherit handler;
  # Plain (mymod.decorate) and "*"-suffixed (matches bare DECORATE and
  # DECORATE.ChexMonsters) -- both needed, not redundant.
  extensions =
    (lib.concatMap (p: [
      p
      "${p}*"
    ]) gzdoomLumpPrefixes)
    ++ [
      "chexmonsters"
      "doommonsters"
      "fluids"
      "green"
      "greenfluids"
      "greenmeat"
      "hereticmonsters"
      "hexenmonsters"
      "meat"
      "supergore"
      "vns"
      "dec"
      "base"
      "inf" # custom bitmap-font descriptor (Kerning/Scale/SpaceWidth/...)
      # script formats
      "acs"
      "zs"
      "zc"
      "zsc"
    ];
}
