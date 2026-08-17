{
  binFile,
  pkgs,
  lib,
  config,
  dirs,
  customLib,
  parallel,
  optimize',
  ...
}:
let
  sleepAmount = "5s"; # Configurable sleep amount
  awwwCommand = "awww img --transition-type=none --resize=fit";
  awwwScript = pkgs.writeText "awww-random" ''
    aww-daemon &
    until awww query; do sleep 1; done
    while true; do
            find "${dirs.wallpapers}" -max-depth 1 \( -type f -o -type l \) \
            | while read -r img; do
                    echo "$(</dev/urandom tr -dc a-zA-Z0-9 | head -c 8):$img"
            done \
            | sort -n | cut -d':' -f2- \
            | while read -r img; do
                    for d in $(awww query | awk '{print $2}' | sed s/://); do # see awww-query(1)
                            [ -z "$img" ] && if read -r img; then true; else break 2; fi
                            rm -f "/tmp/current-wallpaper_$d"
                            ln -s "$img" "/tmp/current-wallpaper_$d"
                            ${awwwCommand} --outputs "$d" "$img"
                            unset -v img # Each image should only be used once per loop
                    done
                    sleep "${sleepAmount}"
            done
    done
  '';

  wallpaperFilePaths = lib.filesystem.listFilesRecursive ./wallpapers;

  importedWallpapers = parallel (map (
    filePath: import filePath ({ inherit pkgs lib; } // customLib)
  )) wallpaperFilePaths;

  allWallpaperDrvs = lib.flatten (parallel (map builtins.attrValues) importedWallpapers);

  optimizedWallpapers = parallel (map optimize') allWallpaperDrvs;

  wallpaperPool =
    pkgs.runCommand "wallpaper-pool"
      {
        wallpapersListFile = pkgs.writeText "wallpaper-paths" (
          builtins.concatStringsSep "\n" optimizedWallpapers
        );

        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        cores=$(( NIX_BUILD_CORES > 0 && NIX_BUILD_CORES < 8 ? NIX_BUILD_CORES : 8 ))
        ${pkgs.findutils}/bin/xargs -a "$wallpapersListFile" -d '\n' -n1 -P"$cores" ${pkgs.bash}/bin/bash -c '
          dir="$1"
          [ -z "$dir" ] && exit 0
          ${pkgs.findutils}/bin/find -L "$dir" -type f -exec ln -sf -t "$out/" {} +
        ' _
      '';

in
{
  options.wallpapers.enable = lib.mkOption {
    type = lib.types.bool;
    # LIGHT=1 (see hosts/modules/lib.nix's shouldFullUpdate for the same
    # impure-env-var convention) skips this for a quick deploy.
    default = (builtins.getEnv "LIGHT") == "";
    description = ''
      Whether to fetch and optimize wallpapers at all. Disable to skip the
      whole (expensive, image-optimization-heavy) wallpaper build graph
      entirely, e.g. while setting up additional remote builders.
    '';
  };

  config = lib.mkIf config.wallpapers.enable {
    # Register them directly to home.file, one entry -- optimizedWallpaperPool
    # is already the flat merged folder (optimizeFolderDynamic's own output),
    # no separate post-optimize merge derivation needed anymore.
    home.file =
      (binFile awwwScript)
      // {
        "Pictures/.context".text = "test";
      }
      // {
        "Pictures/wallpapers".source = wallpaperPool;
      };
  };
}
