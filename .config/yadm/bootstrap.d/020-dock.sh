#!/usr/bin/env bash
set -euo pipefail

# Manual: https://github.com/kcrawford/dockutil

dockutil --remove all --no-restart

apps=(
  "/Applications/Safari.app"
  "/Applications/Google Chrome.app"
  "/Applications/Google Chrome Canary.app"
  "/System/Applications/Mail.app"
  "/Applications/Slack.app"
  "/Applications/Claude.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Warp.app"
  "/Applications/Burp Suite.app"
  "/System/Applications/TextEdit.app"
  "/Applications/Xcode.app"
  "/Applications/Zotero.app"
  "/Applications/1Password.app"
  "/System/Applications/Shortcuts.app"
  "/System/Applications/Calendar.app"
  "/System/Applications/Reminders.app"
  "/System/Applications/Notes.app"
  "/System/Applications/Messages.app"
  "/System/Applications/Music.app"
  "/System/Applications/App Store.app"
  "/System/Applications/System Settings.app"
)

# Apps
for app in "${apps[@]}"; do
  dockutil --add "$app" --no-restart
done

# Apps folder
dockutil --add /Applications --view grid --display folder --sort name --no-restart

# Downloads folder
dockutil --add ~/Library/Mobile\ Documents/com\~apple\~CloudDocs/Downloads --view grid --display folder --sort dateadded --no-restart

killall Dock
