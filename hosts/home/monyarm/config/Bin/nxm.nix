{ pkgs, dirs, ... }:

let
  inherit (pkgs) lib;

  # Define your global fallbacks here
  defaults = {
    type = "windows";
    exe = "${dirs.MediaSSD}/Bethesda/Tools/MO2/nxmhandler.exe";
    prefix = "${dirs.MediaSSD}/Bethesda/WINEPREFIX";
    wine = "${dirs.HOME}/.steam/steam/compatibilitytools.d/GE-Proton10-30/files/bin/wine";
    dotnet = "";
  };

  gameManagers = rec {
    stardewvalley = "${dirs.SteamLibrarySSD}/steamapps/common/Stardew Valley/Stardrop/Internal";

    r2modman = "${dirs.MediaSSD}/Games/r2modman.AppImage";
    tcgcardshopsimulator = r2modman;

    fallout76 = {
      type = "windows";
      exe = "${dirs.MediaSSD}/Bethesda/Tools/76/Fo76ini.exe";
    };
  };

  genBranches =
    attrs:
    let
      # Generate specific game branches
      branches = lib.mapAttrsToList (
        id: cfg:
        let
          # If it's a string, treat as native. If set, merge with defaults.
          conf =
            if lib.isString cfg then
              {
                type = "native";
                cmd = cfg;
              }
            else
              (defaults // cfg);
        in
        ''
          "${id}")
            TYPE="${conf.type}"
            ${
              if conf.type == "native" then
                "CMD=\"${conf.cmd}\""
              else
                ''
                  EXE_PATH="${conf.exe}"
                  WINEPREFIX="${conf.prefix}"
                  WINE_BIN="${conf.wine}"
                  DOTNET_ROOT="${conf.dotnet}"
                ''
            }
            ;;''
      ) attrs;

      # The fallback branch for unmapped games
      fallbackBranch = ''
        *)
          TYPE="${defaults.type}"
          EXE_PATH="${defaults.exe}"
          WINEPREFIX="${defaults.prefix}"
          WINE_BIN="${defaults.wine}"
          DOTNET_ROOT="${defaults.dotnet}"
          ;;'';
    in
    lib.concatStringsSep "\n" (branches ++ [ fallbackBranch ]);

in
pkgs.writeShellScript "nxm" ''
  # Extract Game ID from nxm://{game_id}/...
  URL="$1"
  GAME_ID=$(echo "$URL" | cut -d/ -f3)

  case "$GAME_ID" in
    ${genBranches gameManagers}
  esac

  if [ "$TYPE" = "native" ]; then
      echo "Launching native handler for $GAME_ID: $CMD"
      exec "$CMD" "$@"
  else
      echo "Launching Wine handler for $GAME_ID: $EXE_PATH"
      export WINEPREFIX
      [ -n "$DOTNET_ROOT" ] && export DOTNET_ROOT || unset DOTNET_ROOT
      WINEESYNC=0 "$WINE_BIN" "$EXE_PATH" "$@"
  fi
''
