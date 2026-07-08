#!/usr/bin/env bash
find ~/Pictures/wallpapers -type l | wc -l >>wallpaper-count.txt
mv wallpaper-count.txt wallpaper-count.txt2
\cat wallpaper-count.txt2 | uniq | grep -v '^$' >wallpaper-count.txt
rm wallpaper-count.txt2
