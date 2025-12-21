#!/usr/bin/env bash
# Usage: prefetchSteamCards --appid <appid> [--cardsList "card1,card2,..."]

set -e

while [[ $# -gt 0 ]]; do
  case $1 in
  --appId)
    appId="$2"
    shift 2
    ;;
  --cardNames)
    cardNames="$2"
    shift 2
    ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

if [[ -z $appId ]]; then
  echo "Missing --appId argument" >&2
  exit 1
fi

fetcher_expr="(with import ./lib/fetchers.nix { pkgs = import <nixpkgs> { }; }; fetchSteamCards) "
cmd=(nix-prefetch "$fetcher_expr" --appId "$appId" --sha256 "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
if [[ -n $cardNames ]]; then
  cmd+=(--cardNames --expr "$cardNames")
fi
"${cmd[@]}"
