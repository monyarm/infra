{
  pkgs,
  lib,
  config,
  fetchSteam,
  ...
}:
let
  # Depot 208202 is the bulk of BFG's data; 208203 only adds
  # base/strings/english.lang and base/_sound_pc_en.resources. They do not
  # overlap, so merge both into one basepath, one symlink per entry.
  content = fetchSteam {
    appId = 208200;
    depotId = 208202;
    manifestId = 2267784804404798281;
    os = "windows";
    filelist = [ "regex:^base/.*" ];
    sha256 = "sha256-fq7oYvoQlrJgujR1vuNGQQLe5XMBAR+8pJDMyjZanpw=";
  };
  strings = fetchSteam {
    appId = 208200;
    depotId = 208203;
    manifestId = 1713136676706510174;
    os = "windows";
    filelist = [ "regex:^base/.*" ];
    sha256 = "sha256-xKSMEYnxFqn2E8KfpSnX6vdhwRy72UHrnlT3E6qpDhk=";
  };
  data = pkgs.runCommandLocal "doom3bfg-data" { } ''
    mkdir -p "$out/base"
    for f in ${content}/base/* ${strings}/base/*; do
      ln -s "$f" "$out/base/$(basename "$f")"
    done
  '';
  game = pkgs.writeShellApplication {
    name = "rbdoom3bfg";
    text = ''
      save="''${XDG_DATA_HOME:-$HOME/.local/share}/doom3bfg"
      mkdir -p "$save"
      exec ${lib.getExe pkgs.rbdoom-3-bfg} \
        +set fs_basepath ${data} \
        +set fs_savepath "$save" \
        +set fs_configpath "$save" \
        "$@"
    '';
  };
in
{
  options.games.doom3bfg.enable = lib.mkOption {
    type = lib.types.bool;
    default = (builtins.getEnv "LIGHT") == "";
    description = ''
      Whether to fetch DOOM 3: BFG Edition's data and expose the RBDOOM-3-BFG
      launch entry.
    '';
  };

  config = lib.mkIf config.games.doom3bfg.enable {
    programs.steam.games.DOOM_3_BFG = {
      name = "DOOM 3: BFG Edition";
      inherit game;
      steamAppId = 208200;
    };
  };
}
