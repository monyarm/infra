# Categories Lite: turns PSP/GAME and ISO subfolders into XMB categories.
# Its own settings live in a binary struct at ms0:/seplugins/gclite.bin written
# by its System Settings menu, so `prefix`/`sort` here must be set to match the
# device. Only the layout and the filter file are managed.
{ lib, config, ... }:

let
  inherit (lib)
    mkOption
    types
    ;

  # Distinct categories across every enabled launchable resource. Categories
  # Lite caps the list at 8 including the synthetic "uncategorized" entry.
  limits = import ../../../lib/console/resources.nix { inherit lib; };
  categories =
    let
      from = set: map (r: r.category) (lib.attrValues (lib.filterAttrs (_: r: r.enable) set));
    in
    lib.unique (from config.psp.games ++ from config.psp.homebrew);
in
{
  options.psp.categoriesLite = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Place launchable resources under category directories. The plugin
        itself must still be enabled separately (for ARK-5, through
        psp.cfw.ark5.plugins.categoriesLite).
      '';
    };

    prefix = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether category directories carry the `CAT_` prefix. Must match the
        "Category Prefix" choice in the plugin's System Settings menu. When
        true, only `CAT_` directories are treated as categories.
      '';
    };

    sort = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Number category directories (00, 01, ... in sorted order) so the XMB
        lists them predictably. Requires the plugin's "Sort Categories" option
        to be enabled on the device.
      '';
    };

    filter = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "MyFolder" ];
      description = ''
        Folder names to hide from the category listing. Written one per line to
        `SEPLUGINS/gclite_filter.txt`, which the plugin requires to end with a
        newline.
      '';
    };
  };

  config.psp.files = lib.mkIf (config.psp.categoriesLite.filter != [ ]) {
    "SEPLUGINS/gclite_filter.txt" = {
      text = lib.concatMapStrings (n: "${n}\n") config.psp.categoriesLite.filter;
      owner = "categories-lite";
    };
  };

  config.assertions = [
    {
      assertion = builtins.length categories <= limits.maxCategories;
      message = ''
        console: Categories Lite supports at most ${toString limits.maxCategories}
        categories (including uncategorized); found
        ${toString (builtins.length categories)}:
        ${lib.concatStringsSep ", " categories}
      '';
    }
  ];
}
