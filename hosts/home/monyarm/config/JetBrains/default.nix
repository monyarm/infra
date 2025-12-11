{
  lib,
  dirs,
  mkOutOfStoreSymlink,
  config,
  ...
}:

let
  configPaths = [
    "codestyles"
    "colors"
    "options"
    "plugins"
    "tasks"
    "terminal"
    "inspection"
    "port"
    "disabled_plugins.txt"
  ];

  mkJetBrainsConfig =
    name:
    let
      keyName = lib.toLower (builtins.head (builtins.match "\\.?([A-Za-z]+).*" name));

      basePath = "${dirs.hmConfig}/JetBrains/config/${name}";

      pathConfigs = lib.listToAttrs (
        lib.filter (x: x != null) (
          map (
            item:
            let
              path = "${basePath}/${item}";
            in
            if builtins.pathExists path then
              {
                name = "${name}/${item}";
                value.source = mkOutOfStoreSymlink path;
              }
            else
              null
          ) configPaths
        )
      );

      keyConfig =
        lib.optionalAttrs (builtins.pathExists config.sops.secrets."jetbrains/${keyName}.key".path)
          {
            "${name}/${keyName}.key".source =
              mkOutOfStoreSymlink
                config.sops.secrets."jetbrains/${keyName}.key".path;
          };
    in
    pathConfigs // keyConfig;

  ides = [
    ".CLion2018.3"
    ".PhpStorm2019.1"
    ".WebStorm2019.1"
  ];
in
{
  home.file = lib.mkMerge (map mkJetBrainsConfig ides);
}
