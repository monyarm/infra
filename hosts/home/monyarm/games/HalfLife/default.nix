{
  config,
  lib,
  pkgs,
  autoImport,
  ...
}:
let
  mkHalfLife =
    {
      id,
      gamedir,
      gamelib,
      ...
    }@args:
    (lib.removeAttrs args [
      "id"
      "gamedir"
      "gamelib"
    ])
    // {
      game = pkgs.writeShellApplication {
        name = "xash3d-${id}";
        text = ''
          home="''${XDG_DATA_HOME:-$HOME/.local/share}/xash3d"
          game="$home/${gamedir}"
          # The registry holds the raw depot tree, so the game dir is one level down.
          data="${config.games.halfLife.data.${id}}"
          src="$data/${gamedir}"
          libs="${config.games.halfLife.libs.${id}}"

          mkdir -p "$game/dlls" "$game/cl_dlls" "$game/save"

          # Depot data is linked in read-only; whatever the engine writes
          # (save/, config.cfg, demos) stays a real file in the XDG dir.
          for f in "$src"/*; do
            case "$(basename "$f")" in
              dlls | cl_dlls | save | demos | config.cfg) continue ;;
            esac
            ln -sfn "$f" "$game/$(basename "$f")"
          done

          # Depot 1 ships Text.tga/Font.tga beside the game dir, not inside it.
          for f in "$data"/*.tga; do
            if [ -e "$f" ]; then ln -sfn "$f" "$game/$(basename "$f")"; fi
          done

          if [ -d "$src/dlls" ]; then
            for f in "$src"/dlls/*; do
              if [ -e "$f" ]; then ln -sfn "$f" "$game/dlls/$(basename "$f")"; fi
            done
          fi

          # Our 64-bit game libs replace the depot's 32-bit/Windows ones.
          for f in "$libs"/dlls/*.so; do
            ln -sfn "$f" "$game/dlls/$(basename "$f")"
          done
          for f in "$libs"/cl_dlls/*.so; do
            ln -sfn "$f" "$game/cl_dlls/$(basename "$f")"
          done

          # nixpkgs points this at its own valve copy, which buildSdk=false never installs.
          unset XASH3D_RODIR

          # 64-bit builds carry an _amd64 suffix; plain overrides skip name mangling.
          exec ${lib.getExe config.games.halfLife.engine} \
            -game ${gamedir} \
            -basedir "$home" \
            -clientlib cl_dlls/client_amd64.so \
            -dll dlls/${gamelib}_amd64.so \
            "$@"
        '';
      };
    };
in
{
  options.games.halfLife = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = (builtins.getEnv "LIGHT") == "";
      description = "Whether to fetch the Half-Life campaigns and their game libraries.";
    };

    data = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = "Raw Steam depot trees keyed by game directory (valve, gearbox, bshift).";
    };

    libs = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = "hlsdk-portable builds keyed by game directory.";
    };

    engine = lib.mkOption {
      type = lib.types.package;
      description = "Xash3D-FWGS build the campaigns run on.";
    };
  };

  imports = autoImport ./.;

  config._module.args = { inherit mkHalfLife; };
}
