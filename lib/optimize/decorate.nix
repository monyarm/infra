{ removeLineComments, removeBlankLines, ... }:
# GZDoom directive text lumps (DECORATE, DECALDEF, DECLOLD, SNDINFO,
# MAPINFO, etc., including their dot-suffixed variants like
# "DECORATE.ChexMonsters"): plain line-oriented text, "//" line comments,
# no length-prefixed blocks like DeHackEd's Text sections -- no
# protectAfter needed (verified against real DECALDEF/DECLOLD/SNDINFO/
# DECORATE.* content).
src: src |> removeLineComments { prefixes = [ "//" ]; } |> removeBlankLines { }
