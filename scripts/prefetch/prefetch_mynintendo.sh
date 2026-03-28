#!/usr/bin/env bash
# Usage: prefetch_mynintendo.sh --url <mediaUrl>
set -e

url=""
while [[ $# -gt 0 ]]; do
  case $1 in
  --url)
    url="$2"
    shift 2
    ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

if [[ -z $url ]]; then
  echo "Missing --url argument" >&2
  exit 1
fi

fetcher_expr="(with import ./lib/fetchers.nix {
  pkgs = import <nixpkgs> { };
  dirs = (import ./lib/constants.nix {
    pkgs = import <nixpkgs> { };
    lib = import <nixpkgs/lib>;
  }).dirs;
  importSopsString = (import ./lib/imports.nix {
    pkgs = import <nixpkgs> { };
    lib = import <nixpkgs/lib>;
  }).importSopsString;
}; fetchMyNintendo)"
cmd=(nix-prefetch "$fetcher_expr" --url "$url" --sha256 "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
"${cmd[@]}"
