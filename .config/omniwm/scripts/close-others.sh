#!/usr/bin/env bash
# Closes every other window on the focused window's workspace. With
# --quit-if-last-window, quits the apps whose windows would all be closed instead.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

quit_if_last_window=$(parse_quit_option "$@")

window=$(require_focused_window)
window_id=$(jq -r .id <<<"$window")
workspace=$(jq -r .workspace.rawName <<<"$window")
all_windows=$(windows)
others=$(jq -c --arg id "$window_id" --arg workspace "$workspace" \
  'map(select(.workspace.rawName == $workspace and .id != $id))' <<<"$all_windows")

to_quit='[]'
if [[ $quit_if_last_window == true ]]; then
  to_quit=$(jq -c --argjson others "$others" '
    . as $all
    | [$others[].app.bundleId // empty] | unique
    | map(. as $app | select(
        ([$others[] | select(.app.bundleId == $app)] | length) == ([$all[] | select(.app.bundleId == $app)] | length)))' <<<"$all_windows")
fi

apps=$(jq -r '.[]' <<<"$to_quit")
for app in $apps; do
  quit_app "$app"
done
closes=$(jq -r --argjson quit "$to_quit" \
  '.[] | select((.app.bundleId // "") as $app | $quit | any(. == $app) | not) | .id' <<<"$others")
for other in $closes; do
  ctl window close "$other" >/dev/null
done
