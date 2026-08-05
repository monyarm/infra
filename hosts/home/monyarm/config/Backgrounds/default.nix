{
  binFile,
  pkgs,
  lib,
  config,
  dirs,
  customLib,
  optimizeFolderDynamic,
  parallel,
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

  # Flatten every raw wallpaper file into one pool folder *before*
  # optimizing -- same flattening the final merge step used to do to
  # *optimized* outputs, just moved earlier. Lets the whole ~1600-wallpaper
  # set go through optimizeFolderDynamic as a single build-time dynamic
  # derivation instead of ~1600 individual eval-time `optimize'` calls, each
  # separately paying the full dispatchExt/resolveExt/rename machinery --
  # confirmed via eval-profiler flamegraph to be ~20% of the entire eval on
  # its own (by far the largest single chunk of repo code in the profile).
  rawWallpaperPool =
    pkgs.runCommand "raw-wallpaper-pool"
      {
        inherit allWallpaperDrvs;
        __contentAddressed = true;
        # Not preferLocalBuild: the raw wallpaper fetches are already free
        # to run remotely -- pinning this flatten-into-one-folder step local
        # would drag every one of them back just to symlink them together,
        # same reasoning the old post-optimize merge step (now gone,
        # optimizeFolderDynamic's own output already is the merged folder)
        # used to have.
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        for item in $allWallpaperDrvs; do
          # -L follows the symlinks to the actual files inside the store paths
          # -type f grabs everything, no matter how deep the nesting is
          # -exec ln -s {} $out/ \; symlinks them into the flat target folder
          find -L "$item" -type f -exec ln -s {} "$out/" \;
        done
      '';

  # Wallpapers use prime = true (lossy); games use plain optimize
  # (lossless).
  optimizedWallpaperPool = optimizeFolderDynamic {
    prime = true;
    primeOverride = { };
  } rawWallpaperPool;
in
{
  options.wallpapers.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
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
        "Pictures/wallpapers".source = optimizedWallpaperPool;
      };
  };
}
