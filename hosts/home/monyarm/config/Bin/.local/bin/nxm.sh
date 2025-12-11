#!/bin/sh

export WINEPREFIX="/mnt/mediaSSD/Bethesda/WINEPREFIX"
#export DOTNET_ROOT="$WINEPREFIX/drive_c/Program Files/dotnet"
export DOTNET_ROOT=
export WINE="/home/monyarm/.steam/steam/compatibilitytools.d/GE-Proton9-15/files/bin/wine"

WINEESYNC=0 "$WINE" "/mnt/mediaSSD/Bethesda/Tools/MO2/nxmhandler.exe" "$@"
