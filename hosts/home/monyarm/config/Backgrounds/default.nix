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
  awwwCommand = "awww img --transition-type=none --resize=fit";
  awwwScript = pkgs.writeText "awww-random" ''
    aww-daemon &
    until awww query; do sleep 1; done
    while true; do
            find "${dirs.wallpapers}" -maxdepth 1 \( -type f -o -type l \) \
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
  home.file = (binFile awwwScript) // (linkWallpapers allWallpapers);
}
