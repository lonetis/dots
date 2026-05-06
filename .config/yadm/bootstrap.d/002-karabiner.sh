#!/usr/bin/env bash
set -euo pipefail

# Karabiner-Elements reads PATH from this file when launching shell commands.
# Without it, complex modifications that exec binaries (e.g. from Homebrew)
# fail because Karabiner runs with a minimal PATH.

target_dir="/Library/Application Support/org.pqrs/config"
target_file="$target_dir/karabiner_environment"

sudo install -d -o root -g wheel -m 755 "$target_dir"
sudo tee "$target_file" >/dev/null <<'EOF'
PATH=$HOME/.local/bin:$PATH  # local binaries
PATH=$HOME/.bin:$PATH        # user binaries
PATH=/opt/homebrew/bin:$PATH # homebrew
EOF
sudo chown root:wheel "$target_file"
sudo chmod 644 "$target_file"
