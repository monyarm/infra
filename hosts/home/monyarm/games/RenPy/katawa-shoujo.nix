{ pkgs, mkRenPyGame, ... }:
{
  games.renpy.games.KATAWA_SHOUJO_RE_ENGINEERED = mkRenPyGame {
    name = "katawa-shoujo-re-engineered";
    src = pkgs.katawa-shoujo-re-engineered.src;
    mods = [ ];
    # `renpy . compile` actually runs game init code, including
    # definitions.rpy's Discord RPC thread -- its initial connect() is
    # unguarded upstream (unlike the reconnect path right below it), so it
    # throws DiscordNotFound and prints a Thread-1 traceback whenever the
    # build machine has no Discord running. Harmless (daemon thread), but
    # wrap it the same way the reconnect path already does.
    postPatch = ''
      substituteInPlace game/definitions.rpy --replace-fail '
                  self.rpc = Presence("1176920560253554699")
                  self.rpc.connect()

                  while True:' '
                  self.rpc = Presence("1176920560253554699")
                  try:
                      self.rpc.connect()
                  except Exception:
                      return

                  while True:'
    '';
    # Katawa Shoujo is also on Steam (free) -- patch that real app's
    # LaunchOptions to run this build instead of a synthetic shortcut.
    steamAppId = 3068300;
    steamCdnImagesHash = "sha256-x7VyRZk+fCDbAwDGk7ZMFxqnbrtwUprm4h6ziZNw15w=";
  };
}
