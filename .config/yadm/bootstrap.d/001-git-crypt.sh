#!/usr/bin/env bash
set -euo pipefail

# Decrypts the files listed in ~/.gitattributes with the key the README puts at ~/.git-crypt.
# Skipped once the repo is unlocked: `git-crypt unlock` refuses to run while the work tree
# has uncommitted changes, which ~ nearly always has, so every `dots init` would fail here.

if [[ -f "$(yadm introspect repo)/git-crypt/keys/default" ]]; then
  exit 0
fi

if [[ ! -f "$HOME/.git-crypt" ]]; then
  echo "Error: git-crypt key not found at \$HOME/.git-crypt" >&2
  echo "Place the exported key there before running bootstrap (see README)." >&2
  exit 1
fi

yadm git-crypt unlock "$HOME/.git-crypt"
