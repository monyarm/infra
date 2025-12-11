#!/bin/sh
rm -rf "$HOME"/Documents/PCGen/characters/Pathfinder
fusermount -u "$HOME"/Google\ Drive
rclone mount --buffer-size 16M --drive-chunk-size 128M --dir-cache-time 2m --vfs-read-chunk-size 128M --vfs-read-chunk-size-limit off --vfs-cache-mode full googledrive: "$HOME"/Google\ Drive &
ln -s "$HOME"/Google\ Drive/PathfinderCharacters "$HOME"/Documents/PCGen/characters/Pathfinder
echo "Success?" >/home/monyarm/rc.log
