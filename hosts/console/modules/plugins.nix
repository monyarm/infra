# Plugin registry: `enable = true` pulls dest, runlevel, order and the pinned
# download from lib/console/plugins.nix. Single source of truth for ARK-5's
# PLUGINS.TXT and any later PRO/ME backend.
{
  lib,
  pkgs,
  plugins,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;

  enabled = lib.filterAttrs (_: p: p.enable) config.psp.plugins;

  runlevels = [
    "always"
    "game"
    "umd"
    "homebrew"
    "pops"
    "vsh"
    "launcher"
  ];

  # Lower order sorts earlier. Categories Lite must load first; everything else
  # falls back to name so the list is stable across evaluations.
  ordered = lib.sort (
    a: b:
    let
      ea = enabled.${a};
      eb = enabled.${b};
    in
    if ea.order != eb.order then ea.order < eb.order else a < b
  ) (builtins.attrNames enabled);

  # Enabled plugins missing a binary or a destination.
  incomplete = lib.filterAttrs (_: p: p.source == null || p.dest == null) enabled;
in
{
  options.psp.plugins = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        let
          known = plugins.${name} or null;
          # Registry entries may carry an explicit null (e.g. `source = null`
          # for a plugin we do not ship a binary for); fall through to the
          # fallback in that case too.
          from =
            key: fallback:
            let
              value = known.${key} or null;
            in
            if value == null then fallback else value;
        in
        {
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Install this plugin and register it with the CFW.";
            };

            source = mkOption {
              type = types.nullOr types.path;
              default = from "source" null;
              example = pkgs.fetchurl {
                url = "https://example.invalid/plugin.prx";
                hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
              };
              description = ''
                Derivation or path producing the plugin binary. Defaults to the
                registry's pinned download; set this to use a plugin the
                registry does not ship.
              '';
            };

            dest = mkOption {
              type = types.nullOr types.str;
              default = from "dest" null;
              example = "SEPLUGINS/myplugin.prx";
              description = "Card-relative destination for the plugin binary.";
            };

            runlevel = mkOption {
              type = types.enum runlevels;
              default = from "runlevel" "always";
              description = ''
                ARK-5 runlevel for this plugin. Registry defaults follow each
                plugin's own documentation.
              '';
            };

            order = mkOption {
              type = types.int;
              default = from "order" 0;
              description = ''
                Position in the plugin list; lower sorts earlier. Categories
                Lite is pinned negative because it must load first.
              '';
            };
          };
        }
      )
    );
    default = { };
    description = ''
      PSP plugins to install. Registry plugins can be enabled by name alone:
      `categories-lite`, `missyhud`, and `kill-switch` carry a pinned download;
      `cxmb`, `cwcheat`, and `prxshot` need a user-supplied `source`.
    '';
  };

  # Rendered plugin list, consumed by the CFW backends.
  options.psp.pluginEntries = mkOption {
    type = types.listOf types.unspecified;
    default = [ ];
    internal = true;
    description = "Enabled plugins with resolved path and runlevel, in load order.";
  };

  config.psp.pluginEntries = map (
    name:
    let
      p = enabled.${name};
    in
    {
      inherit name;
      inherit (p) runlevel order;
      devicePath = "ms0:/${p.dest}";
    }
  ) ordered;

  config.psp.files = builtins.listToAttrs (
    map (name: {
      name = enabled.${name}.dest;
      value = {
        source = enabled.${name}.source;
        owner = "plugins.${name}";
      };
    }) ordered
  );

  config.assertions = [
    {
      assertion = incomplete == { };
      message = ''
        console: these enabled plugins have no binary and no destination:
        ${lib.concatStringsSep ", " (lib.attrNames incomplete)}
        Set `source` and `dest`, or enable a registry plugin instead.
      '';
    }
  ];
}
