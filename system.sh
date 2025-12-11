#!/usr/bin/env bash
if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]; then
  export "$(dbus-launch)"
fi

git add .
nix fmt
sudo env PATH="$PATH" nix run 'github:numtide/system-manager' -- switch --flake .#systemConfigs.gentoo-system
