{
  pkgs,
  dirs,
  toTOML,
  ...
}:
let
  # The content of config.toml for YGOFab.
  # This can be customized by the user in their main configuration.
  ygofabConfig = {

    _global = {
      locale = "en"; # Global configurations for YGOFabrica
    };
    "gamedir.main" = {
      # Define one or more `gamedir`s (game directories)
      default = true;
      path = "${dirs.Games}/PC/Linux/ProjectIgnis - EDOPro";
    };

    "picset.regular" = {
      # Define one or more `picset`s (set of card pics)
      default = true;
      mode = "proxy";
      size = "256x";
      ext = "jpg";
      field = true;
    };
  };
in
{
  xdg.configFile."ygofab/config.toml".source = pkgs.writeText "ygofab-config.toml" (
    toTOML ygofabConfig
  );
}
