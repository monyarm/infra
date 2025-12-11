#!/usr/bin/env bash
shopt -s nullglob

for i in *.{bin,md,gb,gbc,gba,nds,n64,ngc,z64}; do
  7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=1024m -ms=on "${i%.*}.7z" "${i%.*}"*.{ips,bps,ups} "$i"
done

for i in *.vb; do
  zstd "$i" -o "$i.zst"
done

for i in *.{sfc,smc,nes,fds}; do
  7z a -mm=Deflate -mfb=258 -mpass=15 -r "${i%.*}.zip" "${i%.*}"*.{ips,bps,ups} "$i"
done
