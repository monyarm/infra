{
  binFile,
  pkgs,
  lib,
  dirs,
  customLib,
  autoImport,
  linkContents,
  ...
}:
let
  linkWallpapers = linkContents "Pictures/wallpapers";

  sleepAmount = "5s"; # Configurable sleep amount
  swwwCommand = "swww img --transition-type=none --resize=fit";
  swwwScript = pkgs.writeText "swww-random" ''
    while true; do
            find "${dirs.wallpapers}" -maxdepth 1 \( -type f -o -type l \) \
            | while read -r img; do
                    echo "$(</dev/urandom tr -dc a-zA-Z0-9 | head -c 8):$img"
            done \
            | sort -n | cut -d':' -f2- \
            | while read -r img; do
                    for d in $(swww query | awk '{print $2}' | sed s/://); do # see swww-query(1)
                            [ -z "$img" ] && if read -r img; then true; else break 2; fi
                            ${swwwCommand} --outputs "$d" "$img"
                            unset -v img # Each image should only be used once per loop
                    done
                    sleep "${sleepAmount}"
            done
    done
  '';

  allWallpapers = builtins.attrValues (autoImport {
    path = ./wallpapers;
    args = {
        inherit
          pkgs
          lib
          ;
      }
      // customLib;
    mode = "merge";
    recursive = true;
  });
in
{
  home.file = (binFile swwwScript) // (linkWallpapers allWallpapers);
}
