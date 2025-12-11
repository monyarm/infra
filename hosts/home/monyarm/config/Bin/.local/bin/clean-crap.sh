#!/bin/bash
# Exit immediately on error.
set -e

# --- System Cleanup Utility ---
# This script performs various cleanup tasks for Nix, Flatpak, Portage, and more.

# --- Helper Functions ---
# Checks if a command exists in the PATH.
command_exists() {
  command -v "$1" &>/dev/null
}

# Runs a command with sudo, but only if the script isn'''t already running as root.
run_sudo() {
  if [[ $EUID -ne 0 ]]; then
    echo "Requesting root privileges for: $*"
    sudo "$@"
  else
    "$@"
  fi
}

# --- Cleanup Functions ---
nix_cleanup() {
  if command_exists nix-env; then
    echo "--- Cleaning up Nix packages ---"
    nix-env --delete-generations old
    nix-collect-garbage --delete-old
    nix-store --gc
    nix-store --optimize
    echo "Nix cleanup complete."
  else
    echo "INFO: nix-env not found, skipping Nix cleanup."
  fi
}

flatpak_cleanup() {
  if command_exists flatpak; then
    echo "--- Cleaning up Flatpak ---"
    flatpak uninstall --unused --noninteractive
    echo "Flatpak cleanup complete."
  else
    echo "INFO: flatpak not found, skipping Flatpak cleanup."
  fi
}

portage_cleanup() {
  echo "--- Cleaning up Portage/Gentoo files ---"
  if command_exists eclean; then
    run_sudo eclean -d distfiles
    run_sudo eclean -d packages
  else
    echo "INFO: eclean not found, skipping eclean tasks."
  fi
  [[ -d "/var/tmp/portage" ]] && run_sudo rm -rf /var/tmp/portage/*
  [[ -d "/var/cache/distfiles" ]] && run_sudo rm -rf /var/cache/distfiles/*
  echo "Portage cleanup complete."
}

journal_cleanup() {
  if command_exists journalctl; then
    echo "--- Cleaning up journald logs ---"
    run_sudo journalctl --vacuum-size=100M
    echo "Journald cleanup complete."
  else
    echo "INFO: journalctl not found, skipping journald cleanup."
  fi
}

docker_cleanup() {
  if command_exists docker; then
    echo "--- Pruning Docker system ---"
    run_sudo docker system prune -af
    echo "Docker cleanup complete."
  else
    echo "INFO: docker not found, skipping Docker cleanup."
  fi
}

npm_cleanup() {
  if command_exists npm; then
    echo "--- Cleaning up npm cache ---"
    npm cache clean --force
    echo "npm cache cleanup complete."
  else
    echo "INFO: npm not found, skipping npm cleanup."
  fi
}

yay_cleanup() {
  if command_exists yay; then
    echo "--- Cleaning up yay cache ---"
    yay -Sc --noconfirm
    echo "yay cleanup complete."
  else
    echo "INFO: yay not found, skipping yay cleanup."
  fi
}

trash_cleanup() {
  if [[ -d "$HOME/.local/share/Trash" ]]; then
    echo "--- Emptying user trash ---"
    rm -rf "$HOME/.local/share/Trash/files/*"
    rm -rf "$HOME/.local/share/Trash/info/*"
    echo "Trash cleanup complete."
  fi
}

# --- Main Script ---
echo "Starting system cleanup..."

nix_cleanup
flatpak_cleanup
portage_cleanup
journal_cleanup
docker_cleanup
npm_cleanup
yay_cleanup
trash_cleanup

echo "System cleanup finished."

# --- Disabled Commands ---
# The following commands were commented out in the original script.
# They are kept here for reference.
#
# sudo rm -rf /nix/var/nix/gcroots/auto/*
# nix-env -e '.*'
# sudo nix-env --delete-generations old
# sudo nix-store --gc
# sudo nix-collect-garbage -d
# sudo chown monyarm:monyarm -R /nix/store
# sudo chmod +rw -R /nix/store
