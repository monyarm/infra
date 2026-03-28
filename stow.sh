#!/usr/bin/env bash
if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]; then
  export "$(dbus-launch)"
fi

git add .
nix fmt
nix run github:nix-community/nh -- home switch --impure --show-activation-logs . -- --option max-call-depth 1000000

find ~/Pictures/wallpapers -type l | wc -l >>wallpaper-count.txt
mv wallpaper-count.txt wallpaper-count.txt2
\cat wallpaper-count.txt2 | uniq | grep -v '^$' >wallpaper-count.txt
rm wallpaper-count.txt2
