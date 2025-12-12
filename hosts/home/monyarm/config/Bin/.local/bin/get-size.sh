#!/bin/bash

find "$1" -type f -exec stat --printf '%b\t%B\n' "{}" \; | awk '{ total += ( $1 * $2 ) }; END { print total }'
