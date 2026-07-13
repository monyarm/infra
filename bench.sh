#!/usr/bin/env bash
if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]; then
  export "$(dbus-launch)"
fi

hostname=$1

export NH_SHOW_ACTIVATION_LOGS=true

git add .
nix fmt

hyperfine --warmup 3 "nix build .#nixosConfigurations.$hostname.config.system.build.toplevel \
  --impure --no-link --no-eval-cache --accept-flake-config \
  --option max-call-depth 1000000"
