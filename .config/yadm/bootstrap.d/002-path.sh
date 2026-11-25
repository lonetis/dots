#!/usr/bin/env bash
set -euo pipefail

# PATH for programs that macOS starts outside a login shell and that therefore never read
# ~/.zprofile. Keep the order in sync with .zprofile.
path="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/.bin"

# Apps started by launchd, e.g. Tinycast, whose script commands run `bash`, `http`, `wg` and
# `node` from Homebrew. Without it they get /usr/bin:/bin:/usr/sbin:/sbin. Applies after a reboot.
sudo launchctl config user path "$path"

# Karabiner-Elements reads the PATH for its shell commands (omniwmctl, node, ~/.bin) from this
# file instead.
karabiner_dir="/Library/Application Support/org.pqrs/config"
sudo install -d -o root -g wheel -m 755 "$karabiner_dir"
printf 'PATH=%s\n' "$path" | sudo tee "$karabiner_dir/karabiner_environment" >/dev/null
sudo chown root:wheel "$karabiner_dir/karabiner_environment"
sudo chmod 644 "$karabiner_dir/karabiner_environment"
