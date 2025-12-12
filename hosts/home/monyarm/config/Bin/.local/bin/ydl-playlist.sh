#!/bin/bash

yt-dlp --get-id "$1" | youtube-dl-parallel -
