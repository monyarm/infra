{
  pkgs,
  lib,
  config,
  fetchSteam,
  sources,
  fetchGitTree,
  ...
}:
let
  tfe = pkgs.theforceengine.overrideAttrs (_: {
    version = sources.tools.theforceengine.date;
    src = fetchGitTree sources.tools.theforceengine;
  });

  data = fetchSteam {
    appId = 32400;
    depotId = 32401;
    manifestId = 2706075311504202822;
    os = "windows";
    filelist = [
      "Game/DARK.GOB"
      "Game/SOUNDS.GOB"
      "Game/SPRITES.GOB"
      "Game/TEXTURES.GOB"
      "Game/JEDI.CFG"
      "Game/CD.ID"
      "Game/LOCAL.MSG"
      "regex:^Game/LFD/.*\.LFD$"
    ];
    sha256 = "sha256-dK7yYk4Vwu6rrrPb+G1GgNThf5zeWvNzmjGlfKm9qBk=";
  };

  # TFE has no CLI flag or env var for the game data path: it only reads
  # sourcePath from [Dark_Forces] in its settings.ini.
  game = pkgs.writeShellApplication {
    name = "theforceengine";
    text = ''
      home="''${TFE_DATA_HOME:-$HOME/.local/share/TheForceEngine}"
      mkdir -p "$home"
      ini="$home/settings.ini"
      touch "$ini"
      sed -i '/^[[:space:]]*sourcePath[[:space:]]*=/d' "$ini"
      if grep -q '^\[Dark_Forces\]' "$ini"; then
        sed -i '/^\[Dark_Forces\]/a sourcePath = ${data}/Game' "$ini"
      else
        printf '\n[Dark_Forces]\nsourcePath = %s\n' "${data}/Game" >> "$ini"
      fi
      export TFE_DATA_HOME="$home"
      exec ${tfe}/bin/theforceengine "$@"
    '';
  };
in
{
  options.games.darkforces.enable = lib.mkOption {
    type = lib.types.bool;
    default = (builtins.getEnv "LIGHT") == "";
    description = ''
      Whether to fetch and register the Dark Forces data.
    '';
  };

  config = lib.mkIf config.games.darkforces.enable {
    # DARK.GOB and the LFD cutscenes must sit together: TFE adds LFD/ to its
    # own search path relative to the source dir.
    programs.steam.games.DARK_FORCES = {
      name = "STAR WARS™: Dark Forces";
      inherit game;
      steamAppId = 32400;
    };
  };
}
