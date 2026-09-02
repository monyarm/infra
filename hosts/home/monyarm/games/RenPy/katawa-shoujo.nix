{ pkgs, mkRenPyGame, ... }:
{
  games.renpy.games.KATAWA_SHOUJO_RE_ENGINEERED = mkRenPyGame {
    name = "katawa-shoujo-re-engineered";
    src = pkgs.katawa-shoujo-re-engineered.src;
    mods = [ ];
    # Katawa Shoujo is also on Steam (free) -- patch that real app's
    # LaunchOptions to run this build instead of a synthetic shortcut.
    steamAppId = 3068300;
    steamCdnImagesHash = "sha256-x7VyRZk+fCDbAwDGk7ZMFxqnbrtwUprm4h6ziZNw15w=";
  };
}
