#!/usr/bin/env bash
if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]; then
  export "$(dbus-launch)"
fi

git add .
nix fmt
nix run github:nix-community/nh -- home switch --impure --show-activation-logs .
#nh home switch --impure --show-activation-logs . #commented because the overlay wont work
