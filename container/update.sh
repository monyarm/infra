#!/usr/bin/env bash
# Source - https://stackoverflow.com/a/49316987

# Posted by yamenk, modified by community. See post 'Timeline' for change history

# Retrieved 2026-01-13, License - CC BY-SA 4.0

docker compose pull
docker compose down
docker compose up -d --remove-orphans
docker image prune
