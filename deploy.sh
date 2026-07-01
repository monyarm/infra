#!/usr/bin/env bash
if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]; then
  export "$(dbus-launch)"
fi

hostname=$1
remote_ip=$2
# if remote_ip is empty, use hostname as remote_ip
if [[ -z $remote_ip ]]; then
  remote_ip=$hostname
fi

export NH_SHOW_ACTIVATION_LOGS=true

git add .
nix fmt

nix run nixpkgs#nixos-rebuild -- switch \
  --flake .#"$hostname" \
  --target-host root@"$remote_ip" \
  --impure \
  --option max-call-depth 1000000
