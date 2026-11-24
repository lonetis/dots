#!/usr/bin/env bash
# Closes the focused window. With --quit-if-last-window, quits the app instead when it
# is the app's last window.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

quit_if_last_window=$(parse_quit_option "$@")

window=$(require_focused_window)
window_id=$(jq -r .id <<<"$window")
bundle_id=$(jq -r '.app.bundleId // empty' <<<"$window")
if [[ $quit_if_last_window == true && -n $bundle_id ]]; then
  app_windows=$(windows --bundle-id "$bundle_id")
  count=$(jq length <<<"$app_windows")
  if ((count <= 1)); then
    quit_app "$bundle_id"
    exit
  fi
fi
ctl window close "$window_id" >/dev/null
