#!/bin/bash

rm -rf ./* ./.*
git clone --depth 1 "$1" .
