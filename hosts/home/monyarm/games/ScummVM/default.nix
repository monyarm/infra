{
  lib,
  config,
  dirs,
  mkOutOfStoreSymlink,
  linkFiles,
  parallel,
  ...
}:

with lib;

{
  # Planned: a `games` option here (attrsOf submodule) where each entry
  # declares one game once and produces both a scummvm.ini section (merged
  # into `config` above) and a programs.steam.games entry -- so a game
  # doesn't need to be declared separately in each place, the way Doom's
  # wads currently are. Not implemented yet; `config`/`firmware` below are
  # the only registries in use for now.
  options.games.scummvm = {
    config = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Attrset fed directly into generators.toINI to produce scummvm.ini.";
    };
    firmware = mkOption {
      type = types.attrsOf (types.either types.package types.str);
      default = { };
      description = "Firmware/ROM files placed under ~/.local/share/scummvm/extra.";
    };
  };

  imports = [
    # keep-sorted start
    ./config.nix
    ./firmware.nix
    # keep-sorted end
  ];

  config = {
    xdg.configFile."scummvm/scummvm.ini".text = generators.toINI { } config.games.scummvm.config;
    xdg.dataFile =
      (parallel (linkFiles "scummvm/extra") (lib.attrValues config.games.scummvm.firmware))
      // {
        "scummvm/saves".source =
          mkOutOfStoreSymlink "${dirs.hmConfig}/ScummVM/.local/share/scummvm/saves";
      };
  };
}
