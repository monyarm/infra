#!/bin/sh
echo "$(qlist -I "$1")" "$(qlist -I "$1" | xargs qdepends -Qqq -F '%[CATEGORY]%[PN]' | tr '\n' ' ')"
