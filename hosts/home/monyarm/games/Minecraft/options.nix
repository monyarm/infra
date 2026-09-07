{ lib, ... }:
with lib;
let
  # Shared submodule type for mods/resourcePacks/datapacks -- one
  # project -> versionKey -> resolved-package-plus-metadata table.
  modVersionsTableType = types.attrsOf (
    types.attrsOf (
      types.submodule {
        options = {
          package = mkOption { type = types.package; };
          gameVersions = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          loaders = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          date = mkOption {
            type = types.str;
            default = "";
          };
        };
      }
    )
  );
in
{
  options.games.minecraft = {
    mods = mkOption {
      type = modVersionsTableType;
      default = { };
      description = "project -> versionKey -> resolved mod package + compatibility metadata, auto-populated from sources.nix's [modrinth] entries.";
    };
    resourcePacks = mkOption {
      type = modVersionsTableType;
      default = { };
      description = "Same shape as mods, for resource packs.";
    };
    datapacks = mkOption {
      type = modVersionsTableType;
      default = { };
      description = "Same shape as mods, for datapacks.";
    };

    modpacks = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = ''
        Either a Modrinth-backed modpack's versions table (project ->
        versionKey -> { package; date; dependencies; }, auto-populated from
        sources.nix's [modrinth-modpack] entries), or a hand-defined custom
        modpack: { minecraftVersion; loader; mods = { name = "latest" |
        versionKey; }; resourcePacks = {...}; datapacks = {...}; }.
      '';
    };

    games = mkOption {
      default = { };
      description = ''
        Instance definitions. The only registry that becomes a Steam
        shortcut. Set only `modpack` to run it exactly as published; add
        `mods`/`resourcePacks`/`datapacks`/`configs`/`files` to layer
        extras on top; omit `modpack` entirely for a fully custom instance
        (`minecraftVersion`/`loader`/`loaderVersion` are then required).
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            modpack = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            modpackVersion = mkOption {
              type = types.str;
              default = "latest";
            };
            minecraftVersion = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            loader = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            loaderVersion = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            resourcePackOrder = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = ''
                Overrides the modpack's own resourcePacks:[...] list
                (first entry = top of the in-game list = highest priority).
                A home-manager activation script patches just that one
                line of the real .minecraft/options.txt on every switch
                (creating the file if absent), leaving every other setting
                the game itself wrote untouched -- null leaves
                resourcePacks alone entirely, letting the game/modpack
                manage it normally.
              '';
            };
            mods = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
            resourcePacks = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
            datapacks = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
            configs = mkOption {
              type = types.attrsOf types.path;
              default = { };
            };
            files = mkOption {
              type = types.attrsOf types.path;
              default = { };
            };
          };
        }
      );
    };
  };
}
