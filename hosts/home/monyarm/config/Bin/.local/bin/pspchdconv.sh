#!/usr/bin/env bash
shopt -s nullglob
for i in *.cso; do maxcso --decompress "$i" -o "${i%.*}.iso"; done
for i in *.iso; do chdman createdvd -hs 2048 -i "$i" -o "${i%.*}.chd"; done
