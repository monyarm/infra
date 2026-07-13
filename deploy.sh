#!/usr/bin/env bash
if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]; then
  export "$(dbus-launch)"
fi

hostname=$1
remote_ip=$2
repo_root="$(cd "$(dirname "$0")" && pwd -P)"
# if remote_ip is empty, use hostname as remote_ip
if [[ -z $remote_ip ]]; then
  remote_ip=$hostname
fi

export NH_SHOW_ACTIVATION_LOGS=true

git add .
nix fmt

# target host needs work due to switch to nh
target_args=()
if [[ $remote_ip != "localhost" ]]; then
  target_args=(--target-host "root@$remote_ip")
fi

nh os switch \
  "$repo_root" --hostname "$hostname" \
  --impure --accept-flake-config \
  -- --option max-call-depth 1000000 \
  "${target_args[@]}"

./wallpaper.sh
