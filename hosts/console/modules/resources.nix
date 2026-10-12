# Games and homebrew, lowered into plain `psp.files` so the deployment engine
# never sees PSP content. Asset layout: homebrew reads ICON0/PIC1/SND0 beside
# EBOOT.PBP; disc images read metadata from inside the image, so external
# assets there are an error, not a no-op.
{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    optionalString
    types
    ;

  res = import ../../../lib/console/resources.nix { inherit lib; };

  # Global defaults consulted when a resource does not set its own asset.
  # Precedence: resource > resource-type default > this > nothing generated.
  pick = explicit: fallback: if explicit != null then explicit else fallback;

  metadataOptions = {
    title = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Display title. Informational; reported, not written to the card.";
    };
    icon = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = ./art/icon.png;
      description = "Icon asset (ICON0.PNG). Homebrew only.";
    };
    background = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = ./art/background.png;
      description = "Background asset (PIC1.PNG). Homebrew only.";
    };
    bgm = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = ./audio/bgm.at3;
      description = "Background music (SND0.AT3). Homebrew only.";
    };
  };

  activeGames = lib.filterAttrs (_: r: r.enable) config.psp.games;
  activeHomebrew = lib.filterAttrs (_: r: r.enable) config.psp.homebrew;

  # Distinct categories across every enabled launchable resource.
  categories =
    let
      from = set: map (r: r.category) (lib.attrValues set);
    in
    lib.unique (from activeGames ++ from activeHomebrew);

  # Deterministic ordering for the plugin's sort feature (v1.6): 00, 01, ...
  sortedCategories = lib.sort (a: b: a < b) categories;

  orderFor = category: lib.lists.findFirstIndex (c: c == category) null sortedCategories;

  # Where a category places a resource, honouring Categories Lite settings.
  # With the plugin disabled, resources sit at the root of their content
  # directory because nothing consumes the category.
  categoryDirFor =
    category:
    optionalString (config.psp.categoriesLite.enable && category != null) (
      res.categoryFolder {
        inherit category;
        prefix = config.psp.categoriesLite.prefix;
        sort = config.psp.categoriesLite.sort;
        order = orderFor category;
      }
      + "/"
    );

  gameType = types.submodule (
    { name, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };
        type = mkOption {
          type = types.enum [
            "psp-iso"
            "psp-cso"
          ];
          default = "psp-iso";
        };
        source = mkOption {
          type = types.path;
          description = "The ISO/CSO image.";
        };
        name = mkOption {
          type = types.str;
          default = name;
          description = "File name on the card, without extension.";
        };
        category = mkOption {
          type = types.str;
          description = "The one category this game belongs to.";
        };
        metadata = mkOption {
          type = types.submodule { options = metadataOptions; };
          default = { };
        };
      };
    }
  );

  homebrewType = types.submodule (
    { name, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };
        package = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Prebuilt derivation or directory. Exclusive with `src`.";
        };
        src = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = ./src;
          description = ''
            Source tree compiled with the PSP toolchain. Exclusive with
            `package`. Must declare a module (PSP_MODULE_INFO) in its source.
          '';
        };
        version = mkOption {
          type = types.str;
          default = "1.0";
          description = "Used when building from `src`.";
        };
        name = mkOption {
          type = types.str;
          default = name;
          description = "Application directory name on the card.";
        };
        category = mkOption {
          type = types.str;
          description = "The one category this application belongs to.";
        };
        metadata = mkOption {
          type = types.submodule { options = metadataOptions; };
          default = { };
        };
      };
    }
  );

  # A homebrew app directory: the package plus any metadata assets, merged into
  # one derivation so the resource stays a single recursive `psp.files` entry.
  mkHomebrew =
    name: package: icon: background: bgm:
    pkgs.runCommand "console-homebrew-${name}" { } ''
      mkdir -p "$out"
      if [ -d ${package} ]; then
        cp -r ${package}/. "$out/"
      else
        cp ${package} "$out/EBOOT.PBP"
      fi
      ${optionalString (icon != null) ''cp ${icon} "$out/ICON0.PNG"''}
      ${optionalString (background != null) ''cp ${background} "$out/PIC1.PNG"''}
      ${optionalString (bgm != null) ''cp ${bgm} "$out/SND0.AT3"''}
      if [ ! -e "$out/EBOOT.PBP" ] && [ ! -e "$out/PARAM.PBP" ] && [ ! -e "$out/PBOOT.PBP" ]; then
        echo "console: homebrew '${name}' has no EBOOT.PBP, PARAM.PBP or PBOOT.PBP" >&2
        exit 1
      fi
    '';

  # Turn a game into a single file declaration.
  gameEntry =
    name: game:
    let
      ext = res.expectedExtension game.type;
      dir = categoryDirFor game.category;
      owner = "games.${name}";
    in
    {
      name = "ISO/" + dir + game.name + ext;
      value = {
        inherit (game) source;
        inherit owner;
      };
    };

  # Turn a homebrew app into a single recursive directory declaration.
  homebrewEntry =
    name: app:
    let
      dir = categoryDirFor app.category;
      icon = pick app.metadata.icon config.psp.metadata.defaultIcon;
      background = pick app.metadata.background config.psp.metadata.defaultBackground;
      bgm = pick app.metadata.bgm config.psp.metadata.defaultBgm;
      # Either a prebuilt package or a source tree compiled by the toolchain.
      package =
        if app.src != null then
          pkgs.pspMkDerivation {
            pname = app.name;
            inherit (app) version src;
          }
        else
          app.package;
    in
    {
      name = "PSP/GAME/" + dir + app.name;
      value = {
        source = mkHomebrew app.name package icon background bgm;
        recursive = true;
        owner = "homebrew.${name}";
      };
    };

  gameEntries = lib.mapAttrsToList gameEntry activeGames;
  homebrewEntries = lib.mapAttrsToList homebrewEntry activeHomebrew;

  # Disc images embed their metadata; external assets would be dead files.
  discImageWithAssets = lib.filterAttrs (
    _: g:
    builtins.any (a: a != null) [
      g.metadata.icon
      g.metadata.background
      g.metadata.bgm
    ]
  ) activeGames;

  # Categories Lite's 30-character folder limit applies to category folder plus
  # homebrew folder; games only contribute their category folder.
  tooLong = lib.filterAttrs (
    name: r: res.displayWidth (categoryDirFor r.category + name) > res.categoryNameLimit
  ) (activeGames // activeHomebrew);

  # A homebrew app is built from `src` or taken prebuilt from `package`, never
  # both and never neither.
  badHomebrew = lib.filterAttrs (_: app: (app.package == null) == (app.src == null)) activeHomebrew;
in
{
  options = {
    psp.metadata = {
      defaultIcon = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Icon used when a homebrew resource does not set its own.";
      };
      defaultBackground = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Background used when a homebrew resource does not set its own.";
      };
      defaultBgm = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Background music used when a homebrew resource does not set its own.";
      };
    };

    psp.games = mkOption {
      type = types.attrsOf gameType;
      default = { };
      description = ''
        PSP ISO/CSO games, keyed by a stable logical identifier. Each game
        declares exactly one `category`.
      '';
    };

    psp.homebrew = mkOption {
      type = types.attrsOf homebrewType;
      default = { };
      description = ''
        Homebrew applications, keyed by a stable logical identifier. Each
        declares exactly one `category`.
      '';
    };
  };

  config = {
    psp.files = builtins.listToAttrs (gameEntries ++ homebrewEntries);

    assertions = [
      {
        assertion = discImageWithAssets == { };
        message = ''
          console: these disc-image games declare icon/background/bgm assets,
          but PSP reads metadata from inside the ISO/CSO and cannot use
          external files:
          ${lib.concatStringsSep ", " (lib.attrNames discImageWithAssets)}
          Remove the assets, or use a homebrew resource instead.
        '';
      }
      {
        assertion = tooLong == { };
        message = ''
          console: these resources exceed Categories Lite's
          ${toString res.categoryNameLimit}-character folder limit:
          ${lib.concatStringsSep ", " (lib.attrNames tooLong)}
          Shorten the category or the resource name.
        '';
      }
      {
        assertion = badHomebrew == { };
        message = ''
          console: these homebrew apps set neither or both of `package` and
          `src`:
          ${lib.concatStringsSep ", " (lib.attrNames badHomebrew)}
          Set exactly one.
        '';
      }
    ];
  };
}
