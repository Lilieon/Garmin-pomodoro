#!/usr/bin/env bash
# Shared post-create (runs once per container, as the remote user).
# Personal hooks: .devcontainer/local/*.sh — gitignored, see local/README.md.
set -euo pipefail
cd "$(dirname "$0")/../.."

sudo chown -R node:node /workspace /home/node/.vscode-server 2>/dev/null || true
gh auth setup-git || true

if [ -z "$(git config --get user.email)" ]; then
  echo ">> git identity unset: add one in .devcontainer/local/post-create.sh (see local/README.md)"
fi

shopt -s nullglob
for hook in .devcontainer/local/*.sh; do
  echo ">> local hook: $hook"
  bash "$hook"
done
