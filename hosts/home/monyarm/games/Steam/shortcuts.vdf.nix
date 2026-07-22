{
  config,
  lib,
  pkgs,
  parallel,
  getFileName,
  fetchSteamCdnImages,
  toKeyValues,
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

  imgExt = p: lib.last (lib.splitString "." (getFileName p));

  # Clean Submodule definition as a configuration set.
  # Using { name, config, ... } lets us access the current key (name) and local configuration values.
  gameSubmodule =
    { name, config, ... }:
    let
      # Auto-fetched library artwork for games declared with a real Steam
      # appid. Lazily evaluated: never forces a network fetch unless a game
      # actually sets both steamAppId and steamCdnImagesHash.
      cdnImages =
        if config.steamAppId != null && config.steamCdnImagesHash != null then
          fetchSteamCdnImages {
            appId = config.steamAppId;
            sha256 = config.steamCdnImagesHash;
          }
        else
          null;
    in
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

        steamAppId = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
          description = ''
            Real Steam appid. When set, this is used instead of the
            synthetic CRC32 shortcut id, enables CDN artwork
            auto-population (together with steamCdnImagesHash), and
            excludes this game from the generated shortcuts.vdf (it gets an
            appmanifest_<id>.acf stub instead, since a real appid shouldn't
            simultaneously be represented as a non-Steam shortcut).
          '';
        };

        steamCdnImagesHash = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Fixed-output hash for fetchSteamCdnImages, obtained via
            scripts/prefetch/prefetchSteamCdnImages.sh. Required alongside
            steamAppId to auto-populate hero/grid/wide/logo artwork.
          '';
        };

        # No `apply` here on purpose: string-coercing a content-addressed
        # derivation (like fetchSteamCdnImages' output) loses its real
        # name/extension, so resolving to a plain path (via resolvePath)
        # happens at each consumption site instead of here.
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
                  default = if cdnImages != null then cdnImages.hero else null;
                };
                grid = lib.mkOption {
                  type = imgType;
                  default = if cdnImages != null then cdnImages.grid else null;
                };
                wide = lib.mkOption {
                  type = imgType;
                  default = if cdnImages != null then cdnImages.wide else null;
                };
                icon = lib.mkOption {
                  type = imgType;
                  default = null;
                };
                logo = lib.mkOption {
                  type = imgType;
                  default = if cdnImages != null then cdnImages.logo else null;
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
          default =
            if config.steamAppId != null then
              config.steamAppId
            else
              generateSteamAppId config.resolvedTargetExe config.name;
        };
      };
    };

  # Convert the games attribute set into a list for JSON / Report processing
  gamesList = lib.attrValues cfg.games;

  # Games with a real appid get an appmanifest_<id>.acf and are excluded
  # from shortcuts.vdf; everything else is a non-Steam shortcut entry.
  acfGamesList = lib.filter (g: g.steamAppId != null) gamesList;
  vdfGamesList = lib.filter (g: g.steamAppId == null) gamesList;

  # Helper to generate clean JSON files per game
  gameToJson =
    g:
    let
      hasLauncher = g.launcher != null;
      resolvedGame = resolvePath g.game;

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
        images = lib.mapAttrs (_: resolvePath) g.images;
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

  # --- REAL shortcuts.vdf (Valve's binary KeyValues format) ---
  # NOT the same format as appmanifest .acf files (see toKeyValues below) —
  # shortcuts.vdf uses type-tagged bytes (object=0x00, string=0x01,
  # int32LE=0x02, terminator=0x08), so it's built here via a small embedded
  # Python writer rather than hand-rolled Nix strings (Nix has no raw byte
  # escapes). The JSON handoff mirrors the existing fetchSteam/filelist
  # passAsFile pattern; the binary output is used directly as a file source,
  # never read back into Nix, so this introduces no new IFD.
  shortcutsVdfWriterScript = pkgs.writeText "json-to-shortcuts-vdf.py" ''
    import json
    import struct
    import sys

    TYPE_OBJECT = 0x00
    TYPE_STRING = 0x01
    TYPE_INT = 0x02
    END = 0x08


    def write_string(f, s):
        f.write(s.encode("utf-8"))
        f.write(b"\x00")


    def write_object(f, obj):
        for key, value in obj.items():
            if isinstance(value, dict):
                f.write(bytes([TYPE_OBJECT]))
                write_string(f, key)
                write_object(f, value)
            elif isinstance(value, bool):
                f.write(bytes([TYPE_INT]))
                write_string(f, key)
                f.write(struct.pack("<I", 1 if value else 0))
            elif isinstance(value, int):
                f.write(bytes([TYPE_INT]))
                write_string(f, key)
                f.write(struct.pack("<I", value & 0xFFFFFFFF))
            else:
                f.write(bytes([TYPE_STRING]))
                write_string(f, key)
                write_string(f, str(value))
        f.write(bytes([END]))


    def main():
        in_path, out_path = sys.argv[1], sys.argv[2]
        with open(in_path) as fh:
            data = json.load(fh)
        with open(out_path, "wb") as f:
            write_object(f, data)


    if __name__ == "__main__":
        main()
  '';

  gameToShortcutEntry =
    g:
    let
      hasLauncher = g.launcher != null;
      resolvedGame = resolvePath g.game;

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

      tagsAttrs = lib.listToAttrs (lib.imap0 (i: t: lib.nameValuePair (toString i) t) g.tags);
    in
    {
      appid = g.appId;
      AppName = g.name;
      # Steam's own convention: the Exe field's *value* includes literal
      # surrounding quote characters, not just shell-style quoting.
      Exe = "\"${g.resolvedTargetExe}\"";
      StartDir = g.workingDirectory;
      icon = if g.images.icon != null then resolvePath g.images.icon else "";
      ShortcutPath = "";
      LaunchOptions = finalArgs;
      IsHidden = 0;
      AllowDesktopConfig = 1;
      AllowOverlay = 1;
      openvr = 0;
      Devkit = 0;
      DevkitGameID = "";
      LastPlayTime = 0;
      tags = tagsAttrs;
    };

  shortcutsVdfData = {
    shortcuts = lib.listToAttrs (
      lib.imap0 (i: g: lib.nameValuePair (toString i) (gameToShortcutEntry g)) vdfGamesList
    );
  };

  shortcutsVdfDrv =
    pkgs.runCommand "shortcuts.vdf"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        shortcutsJson = builtins.toJSON shortcutsVdfData;
        passAsFile = [ "shortcutsJson" ];
      }
      ''
        python3 ${shortcutsVdfWriterScript} "$shortcutsJsonPath" "$out"
      '';

  steamUserDataDir = "${config.home.homeDirectory}/.local/share/Steam/userdata/${cfg.userId}";
  steamConfigDir = "${steamUserDataDir}/config";

  # --- appmanifest_<id>.acf stubs (real-appid mode) ---
  # Plain-text Valve KeyValues (toKeyValues), a completely separate format
  # from the binary shortcuts.vdf above. Placeholder fields are fine — this
  # is a lightweight artwork-only stub, not real installed depot content.
  acfEntry =
    g:
    toKeyValues {
      AppState = {
        appid = g.appId;
        Universe = "1";
        name = g.name;
        StateFlags = "4";
        installdir = builtins.replaceStrings [ " " ] [ "_" ] g.name;
        LastUpdated = "0";
        SizeOnDisk = "0";
      };
    };

  # --- Non-Steam-shortcut grid artwork (real userdata/config/grid path) ---
  # Steam only ever discovers this artwork by these exact filenames, keyed
  # by the shortcut's own appid — there's no field anywhere that can
  # redirect this, so placement here isn't optional/reconfigurable. `icon`
  # is not a grid-folder file; it's the `icon` field inside the shortcut
  # entry itself (handled in gameToShortcutEntry above).
  gridImageFiles = lib.listToAttrs (
    lib.concatMap (
      g:
      let
        appidStr = toString g.appId;
        entries = lib.filterAttrs (_: v: v != null) {
          "${appidStr}_hero" = g.images.hero;
          "${appidStr}_logo" = g.images.logo;
          "${appidStr}" = g.images.wide;
          "${appidStr}p" = g.images.grid;
        };
      in
      lib.mapAttrsToList (fname: rawImg: {
        # imgExt needs the raw value, not resolvePath's output (see the
        # images option above).
        name = ".local/share/Steam/userdata/${cfg.userId}/config/grid/${fname}.${imgExt rawImg}";
        value = {
          source = resolvePath rawImg;
        };
      }) entries
    ) gamesList
  );

in
{
  options.programs.steam = {
    userId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Steam3 account id (the numeric folder name under Steam's userdata/
        directory). Required to place the real shortcuts.vdf and grid
        artwork; without it, only the .steam/games/*.json files (and any
        appmanifest .acf stubs) are written.
      '';
    };

    # Change from listOf to attrsOf for cleaner, merge-safe configurations
    games = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule gameSubmodule);
      default = { };
      description = "Attribute set of configured games to turn into Steam shortcuts.";
    };
  };

  config = lib.mkIf (cfg.games != { }) {
    home = {
      file =
        (lib.foldl'
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
          gamesList
        )
        // (lib.foldl' (
          acc: g:
          acc
          // {
            ".steam/games/appmanifest_${toString g.appId}.acf".text = acfEntry g;
          }
        ) { } acfGamesList)
        // (if cfg.userId != null then gridImageFiles else { });

      # shortcuts.vdf is actively rewritten by Steam itself at runtime
      # (manually-added shortcuts, LastPlayTime, tag edits), so it's copied
      # into place by activation rather than a read-only home.file symlink.
      activation = lib.mkIf (cfg.userId != null) {
        writeShortcutsVdf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${steamConfigDir}/grid"
          $DRY_RUN_CMD cp $VERBOSE_ARG -f ${shortcutsVdfDrv} "${steamConfigDir}/shortcuts.vdf"
        '';
      };

      # Collect all launchers and games into a single list of derivations.
      # When a launcher is set, `game` is just content passed to it (a
      # ROM/wad/etc that can't be "installed" via home.packages), so only
      # the launcher package gets added; otherwise `game` is the package.
      packages = lib.concatLists (
        parallel (map (
          g:
          if g.launcher != null then
            lib.optional (g.launcher.package != null && lib.isDerivation g.launcher.package) g.launcher.package
          else
            lib.optional (g.game != null && lib.isDerivation g.game) g.game
        )) gamesList
      );
    };
  };
}
