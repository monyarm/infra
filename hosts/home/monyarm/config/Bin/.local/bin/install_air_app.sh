#!/bin/sh
find ~/.wine -name "airappinstaller.exe" | head -n 1 | xargs -I % wine "%" "$(winepath -w "$1")"
