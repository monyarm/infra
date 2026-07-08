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

target_args=()
if [[ $remote_ip != "localhost" ]]; then
  target_args=(--target-host "root@$remote_ip")
fi

nixos_rebuild_cmd=(nix run nixpkgs#nixos-rebuild --)
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ $ID == "nixos" ]]; then
    if [[ $remote_ip == "localhost" ]]; then
      if command -v sudo >/dev/null 2>&1; then
        nixos_rebuild_cmd=(sudo --preserve-env=HOME --preserve-env=USER nixos-rebuild)
      elif command -v doas >/dev/null 2>&1; then
        nixos_rebuild_cmd=(doas env "HOME=$HOME" "USER=$USER" nixos-rebuild)
      else
        echo "Error: local deploy requires sudo or doas to run nixos-rebuild."
        exit 1
      fi
    else
      nixos_rebuild_cmd=(nixos-rebuild)
    fi
  fi
fi

"${nixos_rebuild_cmd[@]}" switch \
  --flake "$repo_root#$hostname" \
  --impure --accept-flake-config \
  --option max-call-depth 1000000 \
  "${target_args[@]}"

./wallpaper.sh
