#!/usr/bin/env bash
if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]; then
  export "$(dbus-launch)"
fi

export NH_SHOW_ACTIVATION_LOGS=true

git add .
nix fmt
# nix run github:nix-community/nh -- home switch --impure . -- --option max-call-depth 1000000 --extra-experimental-features pipe-operators
home-manager switch --impure --flake . --option max-call-depth 1000000

./wallpaper.sh
