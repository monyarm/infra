#!/usr/bin/env bash
shopt -s nullglob

rename-config() {
  mv Config.orynt3d config.orynt3d &>/dev/null
}

add-attribute() {
  rename-config
  # shellcheck disable=SC2002
  conf=$(cat ./config.orynt3d | jq '.scancfg.attributes.include += [{"key": "'"$1"'", "value": "'"$2"'"}]' | jq '.scancfg.attributes.exclude += ["'"$1"'"]')
  echo "$conf" >config.orynt3d
}
add-attribute-no-exclude() {
  rename-config
  # shellcheck disable=SC2002
  conf=$(cat ./config.orynt3d | jq '.scancfg.attributes.include += [{"key": "'"$1"'", "value": "'"$2"'"}]')
  echo "$conf" >config.orynt3d
}
add-tag() {
  rename-config
  # shellcheck disable=SC2002
  conf=$(cat ./config.orynt3d | jq '.scancfg.tags.include += ["'"$1"'"]')
  echo "$conf" >config.orynt3d
}

propagation() {
  # shellcheck disable=SC2002
  conf=$(cat "$1" | jq '.scancfg.propagation = '"$2"'')
  echo "$conf" >"$1"
}

folder() {
  # shellcheck disable=SC2002
  conf=$(cat "$1" | jq '.scancfg.fileMode = 1' | jq '.scancfg.modelMode = 2')
  echo "$conf" >"$1"
}

if [[ $1 == "thumb" ]]; then
  for i in *.stl; do stl-thumb "$i" -- "${i%.*}".png; done
elif [[ $1 == "move" ]]; then
  for i in [a-z]*.*; do
    mv "$i" "${i^}"
  done
  mv "Config.orynt3d" "config.orynt3d" &>/dev/null
  readarray -t files <<<"$(find . -maxdepth 1 -type f -name "*.stl" -o -name "*.3mf" | awk '{ print length, $0 }' | sort -n | cut -d" " -f2-)"
  for i in "${files[@]}"; do
    if ls "$i" &>/dev/null; then
      name="${i%.*}"
      mkdir "$name" &>/dev/null
      mv "$name".* {r,R}esize{_,-}{"${name,,}","$name"}.{jpg,png,JPG,PNG} "$name"{-,_}*.* "$name" &>/dev/null
    fi
  done
elif [[ $1 == "init" ]]; then
  if [[ -z $2 ]]; then
    echo "Usage: $0 init <type>"
    exit 1
  fi
  node ~/.local/bin/stlinit.js "$@"
elif [[ $1 == "attr" ]]; then
  add-attribute "$2" "$3"
elif [[ $1 == "attr!" ]]; then
  add-attribute-no-exclude "$2" "$3"
elif [[ $1 == "tag" ]]; then
  add-tag "$2"
elif [[ $1 == "prop" ]]; then
  for i in **/config.orynt3d; do
    propagation "$i" 0
  done
elif [[ $1 == "deprop" ]]; then
  for i in **/config.orynt3d; do
    propagation "$i" 1
  done
elif [[ $1 == "folder" ]]; then
  for i in **/config.orynt3d; do
    folder "$i"
  done
elif [[ $1 == "single-folder" ]]; then
  folder config.orynt3d
fi
