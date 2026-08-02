{
  binFile,
  pkgs,
  lib,
  config,
  dirs,
  customLib,
  optimize',
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

  # Wallpapers use optimize' (lossy); games use plain optimize (lossless).
  optimizedWallpapers = parallel (map optimize') allWallpaperDrvs;
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
    # 2. Register them directly to home.file
    # This creates 1600 small entries in Home Manager instead of 1 giant one.
    home.file =
      (binFile awwwScript)
      // {
        "Pictures/.context".text = "test";
      }
      // {
        "Pictures/wallpapers".source = pkgs.stdenv.mkDerivation {
          name = "optimized-wallpaper-pool";

          inherit optimizedWallpapers;

          # Not preferLocalBuild: optimizedWallpapers is the output of
          # running optimize' over every wallpaper, all already free to run
          # remotely -- pinning this final merge step local
          # would drag every one of those outputs back just to symlink them
          # together, same back-and-forth guardSize had.
          allowSubstitutes = false;

          buildCommand = ''
            mkdir -p $out
            for item in $optimizedWallpapers; do
              # -L follows the symlinks to the actual files inside the store paths
              # -type f grabs everything, no matter how deep the nesting is
              # -exec ln -s {} $out/ \; symlinks them into the flat target folder
              find -L "$item" -type f -exec ln -s {} "$out/" \;
            done
          '';
        };
      };
  };
}
