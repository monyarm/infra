{
  config,
  lib,
  parallel,
  ...
}:

let
  cfg = config.programs.steam;
  username = config.home.username or "user";

  # --- PURE NIX CRC32 IMPLEMENTATION ---
  makeCrcTable =
    let
      # Emulate logical shift right by 1
      shiftRight1 = x: builtins.div x 2;

      crcTableHelper =
        index: crc: i:
        if i == 8 then
          crc
        else
          let
            lowBit = builtins.bitAnd crc 1;
            nextCrc = shiftRight1 crc;
          in
          crcTableHelper index (if lowBit == 1 then builtins.bitXor nextCrc 3988292384 else nextCrc) (i + 1);

      genTable = i: if i == 256 then [ ] else [ (crcTableHelper i i 0) ] ++ (genTable (i + 1));
    in
    genTable 0;

  crcTable = makeCrcTable;

  crc32 =
    str:
    let
      # Emulate logical shift right by 8
      shiftRight8 = x: builtins.div x 256;

      bytes = map (c: lib.strings.charToInt c) (lib.stringToCharacters str);
      foldFn =
        byte: currentCrc:
        let
          tblIndex = builtins.bitAnd (builtins.bitXor currentCrc byte) 255;
          tblValue = builtins.elemAt crcTable tblIndex;
        in
        builtins.bitXor (shiftRight8 currentCrc) tblValue;
    in
    builtins.bitXor (builtins.foldl' (crc: byte: foldFn byte crc) 4294967295 bytes) 4294967295;

  generateSteamAppId =
    exe: name:
    let
      # Discard the store path context so Nix allows us to convert the string characters into integers
      safeExe = builtins.unsafeDiscardStringContext exe;
      quotedTarget = "\"${safeExe}\"";
      crcVal = crc32 (quotedTarget + name);
    in
    builtins.bitOr crcVal 2147483648;

  # --- RESOLUTION HELPERS ---
  resolveExe =
    pkgOrStr:
    if lib.isDerivation pkgOrStr then
      "${lib.getBin pkgOrStr}/bin/${pkgOrStr.meta.mainProgram or (lib.getName pkgOrStr)}"
    else
      pkgOrStr;

  resolvePath = val: if lib.isDerivation val then "${val}" else val;

  coerceArgs =
    val: if lib.isList val then lib.concatStringsSep " " (lib.filter (x: x != "") val) else val;

  # Clean Submodule definition as a configuration set.
  # Using { name, config, ... } lets us access the current key (name) and local configuration values.
  gameSubmodule =
    { name, config, ... }:
    {
      options = {
        game = lib.mkOption {
          type = lib.types.either lib.types.package lib.types.str;
          description = "The game package or absolute path to its executable.";
        };

        args = lib.mkOption {
          type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
          default = "";
          description = "Arguments passed directly to the game (or appended to the launcher).";
          apply = coerceArgs;
        };

        launcher = lib.mkOption {
          default = null;
          description = "Optional launcher to wrap the game.";
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                package = lib.mkOption {
                  type = lib.types.either lib.types.package lib.types.str;
                  description = "The launcher package or path.";
                };
                args = lib.mkOption {
                  type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
                  default = "";
                  description = "Arguments passed to the launcher before the game/rom path.";
                  apply = coerceArgs;
                };
              };
            }
          );
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = name; # Automatically defaults to the attribute set key!
          description = "The name of the shortcut.";
        };

        images = lib.mkOption {
          description = "Artwork paths or packages for Steam UI elements.";
          default = { };
          type = lib.types.submodule {
            options =
              let
                imgType = lib.types.nullOr (lib.types.either lib.types.package lib.types.str);
              in
              {
                hero = lib.mkOption {
                  type = imgType;
                  default = null;
                  apply = lib.mapNullable resolvePath;
                };
                grid = lib.mkOption {
                  type = imgType;
                  default = null;
                  apply = lib.mapNullable resolvePath;
                };
                wide = lib.mkOption {
                  type = imgType;
                  default = null;
                  apply = lib.mapNullable resolvePath;
                };
                icon = lib.mkOption {
                  type = imgType;
                  default = null;
                  apply = lib.mapNullable resolvePath;
                };
                logo = lib.mkOption {
                  type = imgType;
                  default = null;
                  apply = lib.mapNullable resolvePath;
                };
              };
          };
        };

        workingDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/home/${username}/.local/share/games/${config.name}";
          description = "The directory the game runs inside.";
        };

        tags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Steam categories/tags to apply.";
        };

        # --- Calculated Outputs ---
        resolvedTargetExe = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default =
            if config.launcher != null then resolveExe config.launcher.package else resolveExe config.game;
        };

        appId = lib.mkOption {
          type = lib.types.int;
          readOnly = true;
          default = generateSteamAppId config.resolvedTargetExe config.name;
        };
      };
    };

  # Convert the games attribute set into a list for JSON / Report processing
  gamesList = lib.attrValues cfg.games;

  # Helper function to generate clean JSON files per game
  gameToJson =
    g:
    let
      hasLauncher = g.launcher != null;
      resolvedGame = resolveExe g.game;

      finalArgs =
        if hasLauncher then
          let
            parts = [
              g.launcher.args
              "\"${resolvedGame}\""
              g.args
            ];
            nonEmpty = lib.filter (x: x != "" && x != "\"\"") parts;
          in
          lib.concatStringsSep " " nonEmpty
        else
          g.args;

      baseData = {
        inherit (g) appId;
        inherit (g) name;
        exe = g.resolvedTargetExe;
        inherit (g) workingDirectory;
        inherit (g) tags;
        inherit (g) images;
      };

      conditionalData =
        (if finalArgs != "" then { args = finalArgs; } else { })
        // (if hasLauncher then { rom = resolvedGame; } else { });
    in
    builtins.toJSON (baseData // conditionalData);

  # Helper to parse missing artwork types for a single game
  getMissingArtwork =
    g:
    let
      allTypes = [
        "hero"
        "grid"
        "wide"
        "icon"
        "logo"
      ];
      missing = lib.filter (type: g.images.${type} == null) allTypes;
    in
    if missing == [ ] then
      null
    else
      "* ${g.name} (AppId: ${toString g.appId}) is missing: [ ${lib.concatStringsSep ", " missing} ]";

  # Combine all missing reports into a string block
  artworkReportContent =
    let
      reports = lib.filter (x: x != null) (map getMissingArtwork gamesList);
    in
    if reports == [ ] then
      "All games have 100% complete Steam library artwork! 🎉"
    else
      ''
        === STEAM GAMES ARTWORK DEFICIENCY REPORT ===
        Generated at Nix evaluation time.

        ${lib.concatStringsSep "\n" reports}
      '';

in
{
  options.programs.steam = {
    games = lib.mkOption {
      # Change from listOf to attrsOf for cleaner, merge-safe configurations
      type = lib.types.attrsOf (lib.types.submodule gameSubmodule);
      default = { };
      description = "Attribute set of configured games to turn into Steam shortcuts.";
    };
  };

  config = lib.mkIf (cfg.games != { }) {
    home = {
      file =
        lib.foldl'
          (
            acc: g:
            acc
            // {
              ".steam/games/${toString g.appId}.json".text = gameToJson g;
            }
          )
          {
            ".steam/games/artwork-report.txt".text = artworkReportContent;
          }
          gamesList;

      # Collect all launchers and games into a single list of derivations
      packages = lib.concatLists (
        parallel (map (
          g:
          (lib.optional (
            g.launcher != null && g.launcher.package != null && lib.isDerivation g.launcher.package
          ) g.launcher.package)
          ++ (lib.optional (g.game != null && lib.isDerivation g.game) g.game)
        )) gamesList
      );
    };
  };
}
