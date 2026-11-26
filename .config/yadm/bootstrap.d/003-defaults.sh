#!/usr/bin/env bash
set -euo pipefail

# Move windows by holding ctrl + cmd and dragging any part of the window
defaults write -g NSWindowShouldDragOnGesture -bool true

# Disable windows opening animations
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
