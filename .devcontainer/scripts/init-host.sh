#!/usr/bin/env bash
# Host-side hook (initializeCommand): runs before image build and compose up.
# docker compose fails on a missing -f entry, so seed the gitignored override
# from the example on first run.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f docker-compose.override.yml ]; then
  cp docker-compose.override.yml.example docker-compose.override.yml
  echo ">> seeded .devcontainer/docker-compose.override.yml from example (gitignored)"
fi
