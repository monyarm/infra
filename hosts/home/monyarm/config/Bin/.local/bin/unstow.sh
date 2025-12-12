#!/bin/bash

find "$1" -type l -print -execdir bash -c 'export link="$(readlink "$0")";rm "$0"; cp -r --remove-destination "$link" "$0"' {} \;
