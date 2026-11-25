#!/usr/bin/env bash
# Turns macOS menu bar auto-hide back off. OmniWM turns it on for every full-width bar not
# placed below the menu bar, even one at the bottom edge
# (https://github.com/OmniNull/OmniWM/issues/1270). The dots.show-menu-bar LaunchAgent runs
# this whenever the global preferences change. Delete both once that issue is fixed.
set -euo pipefail

# A missing key means auto-hide was never turned on.
hidden=$(defaults read -g _HIHideMenuBar 2>/dev/null) || hidden=0
[[ $hidden == 1 ]] || exit 0

defaults write -g _HIHideMenuBar -bool false
# The menu bar picks up the new value only after this notification, which System Settings posts too.
osascript -l JavaScript -e '
  ObjC.import("Foundation")
  $.NSDistributedNotificationCenter.defaultCenter.postNotificationNameObjectUserInfoDeliverImmediately(
    "AppleInterfaceMenuBarHidingChangedNotification", $(), $(), true)' >/dev/null
