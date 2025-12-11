#!/usr/bin/env bash
shopt -s nullglob
for i in *.iso; do dolphin-tool convert -f rvz -b 131072 -c lzma2 -l 9 -s -i "$i" -o "${i%.*}.rvz"; done
