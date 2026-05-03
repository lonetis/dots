#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "$HOME/.git-crypt" ]]; then
  echo "Error: git-crypt key not found at \$HOME/.git-crypt" >&2
  echo "Place the exported key there before running bootstrap (see README)." >&2
  exit 1
fi

yadm git-crypt unlock "$HOME/.git-crypt"
