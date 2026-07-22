{
  getFile,
  fetchSteam,
  wadFilter,
  ...
}:
let
  DOOM_I_II = fetchSteam {
    filelist = wadFilter;
    appId = 2280;
    depotId = 2281;
    manifestId = 557527948370603647;
    sha256 = "sha256-KIX9HRzQyQ6YawMVYGVk43z88bi55JUy3HNKNTMA2y4=";
  };
in
{
  games.doom.wads = {
    doom = DOOM_I_II |> getFile "rerelease/doom.wad";
    doom2 = DOOM_I_II |> getFile "rerelease/doom2.wad";
    nerve = DOOM_I_II |> getFile "rerelease/nerve.wad";
    masterLevels = DOOM_I_II |> getFile "rerelease/masterlevels.wad";
    sigil = DOOM_I_II |> getFile "rerelease/sigil.wad";
    sigil2 = DOOM_I_II |> getFile "rerelease/sigil2.wad";
    plutonia = DOOM_I_II |> getFile "rerelease/plutonia.wad";
    id1 = DOOM_I_II |> getFile "rerelease/id1.wad";
    tnt = DOOM_I_II |> getFile "rerelease/tnt.wad";
  };
}
